import gymnasium as gym
import numpy as np
from stable_baselines3 import PPO
from godot_rl.wrappers.stable_baselines_wrapper import StableBaselinesGodotEnv
from godot_rl.core.godot_env import GodotEnv

class SelfPlayGodotEnv(gym.Env):
    def __init__(
        self,
        env_path: str = None,
        agents_per_env: int = 2,
        show_window: bool = False,
        speedup: int = 1,
        random_play: bool = False,
        port=GodotEnv.DEFAULT_PORT,
        action_repeat: int = 4
    ):  
        self.env = StableBaselinesGodotEnv(
            env_path=env_path,
            show_window=show_window,
            speedup=speedup,
            port=port,
            **{
                "action_repeat": action_repeat,
            }
        )
        self.random_play = random_play
        self.observation_space = self.env.observation_space.spaces["obs"]
        self.action_space = self.env.action_space
        self.agents_per_env = agents_per_env - 1
        self.models = [None for _ in range(self.agents_per_env)]
        self.latest_models_obs = [None for _ in range(self.agents_per_env)]

    def set_model(self, agent_num: int, model_path: str):
        self.models[agent_num] = PPO.load(model_path)
        print(f"Loaded model {model_path} for agent {agent_num}")
    
    def choose_model(self, agent_num: int, model_paths: list[str]):
        model_path = model_paths[np.random.randint(len(model_paths))]
        self.set_model(agent_num, model_path)
    
    def choose_models(self, model_paths: list[str]):
        for i in range(self.agents_per_env):
            self.choose_model(i, model_paths)
    
    def step(self, action: np.ndarray):
        model_actions = self.get_model_actions()
        obs, rewards, done, info = self.env.step(np.array([action] + model_actions))
        obs = obs["obs"]
        step_obs = self.parse_obs(obs)
        return step_obs, rewards[0], (True in done), False, {}
    
    def reset(self, seed=0):
        obs = self.env.reset()["obs"]
        return self.parse_obs(obs), {}
    
    def parse_obs(self, obs: np.ndarray):
        step_obs = np.array(obs[0], np.float32)
        for i in range(self.agents_per_env):
            self.latest_models_obs[i] = np.array(obs[i+1], np.float32)
        return step_obs
    
    def get_model_action(self, agent_num: int):
        model_action = self.action_space.sample()
        if self.random_play:
            return model_action
        model_obs = self.latest_models_obs[agent_num]
        model = self.models[agent_num]
        if model is not None and model_obs is not None:
            model_action, _ = model.predict(model_obs, deterministic=True)
        return model_action
    
    def get_model_actions(self):
        model_actions = []
        for i in range(self.agents_per_env):
            model_action = self.get_model_action(i)
            model_actions.append(model_action)
        return model_actions
