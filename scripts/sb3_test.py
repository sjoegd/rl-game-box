from argparse import ArgumentParser
from pathlib import Path
import numpy as np
from stable_baselines3 import PPO

from wrappers.selfplay_godot_env import SelfplayGodotEnv


if __name__ == "__main__":
    
    parser = ArgumentParser(allow_abbrev=False)
    
    parser.add_argument(
        "--env_path",
        default=None,
        type=str
    )
    
    parser.add_argument(
        "--model_paths",
        default=None,
        type=str,
    )
    
    parser.add_argument(
        "--agents_per_env",
        default=1,
        type=int
    )
    
    parser.add_argument(
        "--action_repeat",
        default=4,
        type=int
    )
    
    parser.add_argument(
        "--sessions",
        default=1,
        type=int
    )
    
    args, _ = parser.parse_known_args()
    
    model_paths = [Path(p) for p in args.model_paths.split(", ")]
    main_model_path = model_paths[0]
    other_model_paths = model_paths[1:]
    
    if len(other_model_paths) == 0:
        other_model_paths = model_paths
    
    env = SelfplayGodotEnv(
        env_path=args.env_path,
        agents_per_env=args.agents_per_env,
        action_repeat=args.action_repeat,
        show_window=True
    )
    
    if len(other_model_paths) == args.agents_per_env - 1:
        env.set_models(other_model_paths)
    else:
        env.set_models(np.random.choice(other_model_paths, args.agents_per_env - 1))
    
    main_model = PPO.load(main_model_path, env=env)
    
    try:
    
        for _ in range(args.sessions):
            obs = env.reset()
            done = False
            while not done:
                action, _ = main_model.predict(obs, deterministic=True)
                obs, _, done, _ = env.step(action)
    
    finally:
        
        env.close()