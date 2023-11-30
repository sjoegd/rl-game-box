import argparse
import os
import pathlib
import shutil
import json
import numpy as np

from stable_baselines3 import PPO
from stable_baselines3.common.vec_env import DummyVecEnv
from stable_baselines3.common.vec_env.vec_monitor import VecMonitor

from godot_rl.core.godot_env import GodotEnv
from scripts.wrappers.old.selfplay_godot_env_async import SelfPlayGodotEnvAsync
from wrappers.selfplay_godot_env import SelfPlayGodotEnv

"""
TODO:
    - Add support for better PPO hyperparameters
    - Add support for arg overwrites when resuming training
    - Training should also support single agent env (remove train script from godot-rl-agents)
        - Maybe works automatically with selfplay env set to 1 agent
            - Test this
"""

if __name__ == "__main__":
    
    parser = argparse.ArgumentParser(allow_abbrev=False)

    parser.add_argument(
        "--is_async",
        default=False,
        type=bool
    )

    parser.add_argument(
        "--env_path",
        default=None,
        type=str
    )

    parser.add_argument(
        "--save_parent_folder_path",
        default=None,
        type=str
    )

    parser.add_argument(
        "--save_model_name",
        default=None,
        type=str
    )
    
    parser.add_argument(
        "--resume_training",
        default=False,
        type=bool
    )

    parser.add_argument(
        "--viz",
        default=False,
        type=bool,
    )

    parser.add_argument(
        "--speedup",
        default=12,
        type=int,
    )

    parser.add_argument(
        "--agents_per_env",
        default=2,
        type=int
    )

    parser.add_argument(
        "--n_parallel",
        default=1,
        type=int,
    )
    
    parser.add_argument(
        "--action_repeat",
        default=4,
        type=int
    )

    parser.add_argument(
        "--max_past_agents",
        default=10,
        type=int
    )

    parser.add_argument(
        "--total_timesteps",
        default=1_000_000,
        type=int
    )

    parser.add_argument(
        "--total_iterations",
        default=100,
        type=int
    )

    args, _ = parser.parse_known_args()
    base_port = GodotEnv.DEFAULT_PORT
    
    def make_env(p: int):
        def make_env_p():
            return SelfPlayGodotEnv(
                env_path=args.env_path,
                show_window=args.viz,
                speedup=args.speedup,
                agents_per_env=args.agents_per_env,
                action_repeat=args.action_repeat,
                port=base_port+p
            )
        return make_env_p

    save_parent_path = pathlib.Path(args.save_parent_folder_path)
    save_path = pathlib.Path(save_parent_path, args.save_model_name)
    temp_path = pathlib.Path(save_parent_path, "temp")
    json_path = pathlib.Path(save_parent_path, "args.json")

    if args.resume_training:
        json_args = json.load(open(json_path, "r"))
        args.__dict__.update(json_args)
        print("Resuming training with args: {}".format(json_args))
    
    if not os.path.exists(save_parent_path):
        os.mkdir(save_parent_path)
    if not os.path.exists(temp_path):
        os.mkdir(temp_path)

    if args.is_async:
        venv = SelfPlayGodotEnvAsync(
            env_path=args.env_path,
            port=base_port,
            agents_per_env=args.agents_per_env,
            n_parallel=args.n_parallel,
            speedup=args.speedup,
            action_repeat=args.action_repeat,
            show_window=args.viz,
        )
    else:
        env_makers = [make_env(p) for p in range(args.n_parallel)]
        venv = DummyVecEnv(env_makers)
    env = VecMonitor(venv)

    past_agent_paths = []
    max_past_agents = args.max_past_agents
    total_timesteps = args.total_timesteps
    total_iterations = args.total_iterations
    steps_per_iteration = total_timesteps // total_iterations

    if not args.resume_training:
        agent = PPO(policy="MlpPolicy", env=env, verbose=1)
    else:
        agent = PPO.load(save_path, env=env, verbose=1)

    try:
        for it in range(total_iterations):
            print("--------------------")
            print("Iteration: {}".format(it))
            print("--------------------")
            
            agent.learn(steps_per_iteration, reset_num_timesteps=False)
            
            past_agent_path = pathlib.Path(temp_path, "agent_{}".format(it))
            past_agent_paths.append(past_agent_path)
            agent.save(past_agent_path)
            agent.save(save_path)
            
            if len(past_agent_paths) > max_past_agents:
                removed_past_agent_path = past_agent_paths.pop(np.random.randint(len(past_agent_paths)))
                os.remove(removed_past_agent_path.with_suffix(".zip"))
            
            if args.is_async:
                venv.choose_models(past_agent_paths)
            else:
                venv.env_method("choose_models", past_agent_paths)
    finally:
        json.dump(vars(args), open(json_path, "w"))
        shutil.rmtree(temp_path)
        agent.save(save_path)
        env.close()