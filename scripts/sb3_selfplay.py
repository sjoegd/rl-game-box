import argparse
import os
import pathlib
import numpy as np

from stable_baselines3 import PPO
from stable_baselines3.common.vec_env.vec_monitor import VecMonitor
from stable_baselines3.common.vec_env import DummyVecEnv

from godot_rl.core.godot_env import GodotEnv
from wrappers.selfplay_godot_env import SelfPlayGodotEnv
from wrappers.selfplay_godot_env_async import SelfPlayGodotEnvAsync

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
        "--viz",
        default=False,
        type=bool,
    )

    parser.add_argument(
        "--speedup",
        default=15,
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
    
    parser.add_argument(
        "--inference",
        default=False,
        type=bool
    )
    
    parser.add_argument(
        "--load_model_path",
        default=None,
        type=str
    )
    
    parser.add_argument(
        "--num_episodes",
        default=10,
        type=int
    )
    
    parser.add_argument(
        "--against_random",
        default=False,
        type=bool
    )

    args, _ = parser.parse_known_args()
    base_port = GodotEnv.DEFAULT_PORT

    def make_env(p):
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

    if args.inference:
        
        # Inference Setup
        
        env = make_env(0)()
        model_path = pathlib.Path(args.load_model_path)
        if not args.against_random:
            env.choose_models([model_path])
        agent = PPO.load(model_path)
        
        for ep in range(args.num_episodes):
            done = False
            obs, _ = env.reset()
            while not done:
                action, _ = agent.predict(obs, deterministic=True)
                obs, reward, done, term, info = env.step(action)
    else:
        
        # Selfplay Setup
        
        save_parent_path = pathlib.Path(args.save_parent_folder_path)
        save_path = pathlib.Path(save_parent_path, args.save_model_name)
        temp_path = pathlib.Path(save_parent_path, "temp")

        if not os.path.exists(save_parent_path):
            os.mkdir(save_parent_path)
        if not os.path.exists(temp_path):
            os.mkdir(temp_path)

        env_makers = [make_env(p) for p in range(args.n_parallel)]

        if args.is_async:
            venv = SelfPlayGodotEnvAsync(
                env_path=args.env_path,
                show_window=args.viz,
                speedup=args.speedup,
                agents_per_env=args.agents_per_env,
                action_repeat=args.action_repeat,
                port=base_port,
                n_parallel=args.n_parallel
            )
        else:
            venv = DummyVecEnv(env_makers)
        env = VecMonitor(venv)

        past_agent_paths = []
        max_past_agents = args.max_past_agents
        total_timesteps = args.total_timesteps
        total_iterations = args.total_iterations
        steps_per_iteration = total_timesteps // total_iterations

        agent = PPO(policy="MlpPolicy", env=env, verbose=1)

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
                os.remove(removed_past_agent_path + ".zip")
            
            if args.is_async:
                venv.choose_models(past_agent_paths)
            else:
                venv.env_method("choose_models", past_agent_paths)

        agent.save(save_path)
        env.close()