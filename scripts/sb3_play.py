from argparse import ArgumentParser
from pathlib import Path
import numpy as np

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
    
    env = SelfplayGodotEnv(
        env_path=args.env_path,
        agents_per_env=args.agents_per_env,
        action_repeat=args.action_repeat,
        show_window=True
    )
    
    if len(model_paths) == args.agents_per_env - 1:
        env.set_models(model_paths)
    elif len(model_paths) > 0:
        env.set_models(np.random.choice(model_paths, args.agents_per_env - 1))
    
    try:
        
        env.reset()
        
        for _ in range(args.sessions):
            done = False
            while not done:
                _, _, done, _ = env.step([np.zeros(shape=env.action_space.shape)])
    
    finally:
    
        env.close()