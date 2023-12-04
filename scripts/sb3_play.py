import argparse
import pathlib

from wrappers.selfplay_godot_env import SelfPlayGodotEnv

if __name__ == "__main__":
    
    parser = argparse.ArgumentParser(allow_abbrev=False)
    
    parser.add_argument(
        "--env_path",
        default=None,
        type=str
    )
    
    parser.add_argument(
        "--agents_per_env",
        default=2,
        type=int
    )
    
    parser.add_argument(
        "--action_repeat",
        default=4,
        type=int
    )
    
    parser.add_argument(
        "--load_model_paths",
        default=None,
        type=str
    )
    
    parser.add_argument(
        "--num_episodes",
        default=5,
        type=int
    )
    
    args, _ = parser.parse_known_args()
    
    model_paths = args.load_model_paths.split(", ")
    model_paths = [pathlib.Path(path) for path in model_paths]
    
    env = SelfPlayGodotEnv(
        env_path=args.env_path,
        speedup=1,
        agents_per_env=args.agents_per_env,
        action_repeat=args.action_repeat,
        show_window=True
    )
    
    env.choose_models(model_paths)
    
    for _ in range(args.num_episodes):
        done = False
        env.reset()
        while not done:
            _, _, done, _, _ = env.step(env.action_space.sample())
    
    env.close()