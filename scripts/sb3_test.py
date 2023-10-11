import pathlib
import argparse
from stable_baselines3 import PPO
from wrappers.selfplay_godot_env import SelfPlayGodotEnv

if __name__ == "__main__":
    
    parser = argparse.ArgumentParser(allow_abbrev=False)
    
    parser.add_argument(
        "--env_path",
        default=None,
        type=str
    )
    
    parser.add_argument(
        "--speedup",
        default=1,
        type=int
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
        default=1,
        type=int
    )
    
    args, _ = parser.parse_known_args()
    
    print(args.env_path)
    
    env = SelfPlayGodotEnv(
        env_path=args.env_path,
        speedup=args.speedup,
        agents_per_env=args.agents_per_env,
        action_repeat=args.action_repeat,
        show_window=True
    )
    
    model_paths = args.load_model_paths.split(",")
    model_paths = [pathlib.Path(path) for path in model_paths]
    
    agent = PPO.load(model_paths[0])
    opponent_paths = model_paths[1:]
    
    for _ in range(args.num_episodes):
        if len(opponent_paths) > 0:
            env.choose_models(opponent_paths)
        done = False
        obs, _ = env.reset()
        while not done:
            action, _ = agent.predict(obs, deterministic=True)
            obs, _, done, _, _ = env.step(action)