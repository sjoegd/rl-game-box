from pathlib import Path
import numpy as np
from stable_baselines3 import PPO
from godot_rl.wrappers.stable_baselines_wrapper import StableBaselinesGodotEnv
from stable_baselines3.common.vec_env.base_vec_env import VecEnv
from godot_rl.core.godot_env import GodotEnv

"""
A custom wrapper around the GodotEnv that allows
agents to play against other models with multiple parallel envs and
multiple games instances per env.
"""
class SelfplayGodotEnv(VecEnv):
    
    def __init__(
        self,
        env_path: str = None,
        agents_per_env: int = 1,
        games_per_env: int = 1,
        n_parallel: int = 1,
        show_window: bool = False,
        speedup: int = 1,
        port=GodotEnv.DEFAULT_PORT,
        action_repeat: int = 4
    ):
        self.env = StableBaselinesGodotEnv(
            env_path=env_path,
            n_parallel=n_parallel,
            show_window=show_window,
            speedup=speedup,
            port=port,
            **{
                "action_repeat": action_repeat,
            }
        )
        
        self.observation_space = self.env.observation_space.spaces["obs"]
        self.action_space = self.env.action_space
        self.n_parallel = n_parallel
        self.agents_per_env = agents_per_env
        self.games_per_env = games_per_env
        self.model_handler = SelfplayModelHandler(self, self.agents_per_env, self.num_envs)
        self.previous_obs = [None for _ in range(self.agents_per_env * self.num_envs)]
    
    def set_models(self, models: list[Path]):
        for i in range(self.agents_per_env - 1):
            self.model_handler.set_model(i, models[i])
    
    def step(self, step_actions: np.ndarray):
        
        all_actions = [None]*self.num_envs*self.agents_per_env
        
        #for game in range(self.num_envs):
        #    all_actions.append(step_actions[game])
        #    for agent in range(1, self.agents_per_env):
        #        all_actions.append(self.model_handler.get_action(agent-1, self.previous_obs[game * self.agents_per_env + agent]))
        
        for agent in range(self.agents_per_env):
            for game in range(self.num_envs):
                action = step_actions[game] if agent == 0 else self.model_handler.get_action(agent-1, self.previous_obs[game * self.agents_per_env + agent])
                all_actions[game * self.agents_per_env + agent] = action
        
        obs, rewards, dones, _ = self.env.step(np.array(all_actions))
        obs = obs["obs"]
        self.previous_obs = obs
        
        step_obs, step_rewards, step_dones = self.parse_step(obs, rewards, dones)
        
        return step_obs, step_rewards, step_dones, [{} for _ in range(self.num_envs)]
    
    def parse_step(self, obs: np.ndarray, rewards: np.ndarray, dones: np.ndarray) -> (np.ndarray, np.ndarray, np.ndarray):
        step_obs = []
        step_rewards = []
        step_dones = []
        
        for i in range(len(obs)):
            if i % self.agents_per_env == 0:
                step_obs.append(obs[i])
                step_rewards.append(rewards[i])
                step_dones.append(dones[i])
        
        return np.array(step_obs), np.array(step_rewards), np.array(step_dones)
    
    def parse_step_obs(self, obs: np.ndarray) -> np.ndarray:
        step_obs = []
        
        for i in range(len(obs)):
            if i % self.agents_per_env == 0:
                step_obs.append(obs[i])
        
        return np.array(step_obs)
    
    def reset(self, seed=0):
        obs = self.env.reset()["obs"]
        self.previous_obs = obs
        return self.parse_step_obs(obs)
    
    def close(self):
        self.env.close()
    
    @property
    def num_envs(self) -> int:
        return self.n_parallel * self.games_per_env
        
    def env_is_wrapped(self, wrapper_class=None, indices=None) -> list[bool]:
        return [False] * self.num_envs

    def env_method(self):
        raise NotImplementedError()

    def get_attr(self, attr_name: str, indices = None) -> list[any]:
        if attr_name == "render_mode":
            return [None for _ in range(self.num_envs)]
        raise NotImplementedError()

    def seed(self, seed = None):
        raise NotImplementedError()

    def set_attr(self):
        raise NotImplementedError()

    def step_async(self, actions: np.ndarray) -> None:
        self.results = self.step(actions)

    def step_wait(self): 
        return self.results
    

class SelfplayModelHandler:
    
    def __init__(self, selfplay_env: SelfplayGodotEnv, total_agents: int, total_games: int):
        self.selfplay_env = selfplay_env
        self.total_agents = total_agents
        self.total_games = total_games
        self.models: list[PPO] = [None for _ in range(self.total_agents - 1)]
    
    def set_model(self, agent: int, model_path: str):
        self.models[agent] = PPO.load(model_path)
        print(f"Loaded model {model_path} for agent {agent}")
    
    def get_action(self, agent: int, obs: np.ndarray) -> np.ndarray:
        model  = self.models[agent]
        
        if model is None:
            return self.selfplay_env.action_space.sample()
        
        action, _ = model.predict(obs, deterministic=True)
        
        return action