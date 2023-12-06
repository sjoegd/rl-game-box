import argparse
import os
import pathlib
import shutil
import json
import numpy as np

from stable_baselines3 import PPO
from stable_baselines3.common.vec_env.vec_monitor import VecMonitor

from wrappers.selfplay_godot_env import SelfplayGodotEnv

if __name__ == "__main__":
    
    parser = argparse.ArgumentParser(allow_abbrev=False)

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
        default=1,
        type=int
    )
    
    parser.add_argument(
        "--games_per_env",
        default=1,
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
    save_parent_path = pathlib.Path(args.save_parent_folder_path)
    save_path = pathlib.Path(save_parent_path, args.save_model_name)
    temp_path = pathlib.Path(save_parent_path, "temp")
    json_path = pathlib.Path(save_parent_path, "args.json")

    if args.resume_training:
        json_args = json.load(open(json_path, "r"))
        args.__dict__.update(json_args)
        args.__dict__["resume_training"] = True
        print("Resuming training with args: {}".format(json_args))
    
    if not os.path.exists(save_parent_path):
        os.mkdir(save_parent_path)
    if not os.path.exists(temp_path):
        os.mkdir(temp_path)

    venv = SelfplayGodotEnv(
        env_path=args.env_path,
        agents_per_env=args.agents_per_env,
        games_per_env=args.games_per_env,
        n_parallel=args.n_parallel,
        show_window=args.viz,
        speedup=args.speedup,
        action_repeat=args.action_repeat
    )
    env = VecMonitor(venv)

    past_agent_paths = []
    max_past_agents = args.max_past_agents
    total_timesteps = args.total_timesteps
    total_iterations = args.total_iterations
    steps_per_iteration = total_timesteps // total_iterations

    if not args.resume_training:
        agent = PPO(
            policy="MlpPolicy", 
            env=env, 
            verbose=1,
            batch_size=512,
            ent_coef=0.01,
            gae_lambda=0.95,
            clip_range=0.2,
            learning_rate=1e-5,
            n_epochs=32,
            gamma=0.99,
            max_grad_norm=0.5          
        )
    else:
        print("LOADED MODEL")
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
            
            venv.set_models(np.random.choice(past_agent_paths, args.agents_per_env - 1, replace=True))

    finally:
        
        json.dump(vars(args), open(json_path, "w"))
        shutil.rmtree(temp_path)
        agent.save(save_path)
        env.close()