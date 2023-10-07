from typing import Any, List
import numpy as np
from stable_baselines3 import PPO
from godot_rl.wrappers.stable_baselines_wrapper import StableBaselinesGodotEnv
from stable_baselines3.common.vec_env.base_vec_env import VecEnv
from godot_rl.core.godot_env import GodotEnv

# TODO: Test
# TODO: Add support for a model per n_parallel (currently only supports 1 model for all)

class SelfPlayGodotEnvAsync(VecEnv):
    def __init__(
        self,
        env_path: str = None,
        agents_per_env: int = 2,
        show_window: bool = False,
        speedup: int = 1,
        port=GodotEnv.DEFAULT_PORT,
        n_parallel: int = 1,
        action_repeat: int = 1
    ):  
        self.env = StableBaselinesGodotEnv(
            env_path=env_path,
            show_window=show_window,
            speedup=speedup,
            port=port,
            n_parallel=n_parallel,
            **{
                "action_repeat": action_repeat,
            }
        )
        self.observation_space = self.env.observation_space.spaces["obs"]
        self.action_space = self.env.action_space
        self.n_parallel = n_parallel
        self.agents_per_env = agents_per_env - 1
        self.models = [None for _ in range(self.agents_per_env)]
        self.latest_models_obs = [[None for _ in range(self.n_parallel)] for _ in range(self.agents_per_env)]

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
        
        total_actions = []
        for i in range(self.n_parallel):
            total_actions.append(action[i])
            total_actions.append(model_actions[i])
        
        obs, rewards, dones, _ = self.env.step(np.array(total_actions))
        obs = obs["obs"]
        
        step_obs = self.parse_obs(obs)
        
        # Get the rewards for the first player for every parallel env
        step_rewards = []
        for i in range(self.n_parallel):
            step_rewards.append(rewards[i*self.agents_per_env])
        step_rewards = np.array(step_rewards, np.float32)
        
        # Get the dones for each parallel env
        step_dones = []
        for i in range(self.n_parallel):
            env_dones = dones[i*self.agents_per_env:(i+1)*self.agents_per_env]
            step_dones.append(True in env_dones)
        step_dones = np.array(step_dones, bool)
            
        return step_obs, step_rewards, step_dones, [{} for _ in range(self.n_parallel)]
    
    def reset(self, seed=0):
        obs = self.env.reset()["obs"]
        return self.parse_obs(obs)
    
    def close(self):
        self.env.close()
    
    def parse_obs(self, obs: np.ndarray):
        step_obs = []
        for i in range(self.n_parallel):
            step_obs.append(obs[i*self.agents_per_env])
        step_obs = np.array(step_obs, np.float32)
        
        for i in range(self.agents_per_env):
            self.latest_models_obs[i] = [None for _ in range(self.n_parallel)]
            for j in range(self.n_parallel):
                self.latest_models_obs[i][j] = obs[j*self.agents_per_env + (i + 1)]
            self.latest_models_obs[i] = np.array(self.latest_models_obs[i], np.float32)
        
        return step_obs
    
    def get_model_action(self, agent_num: int):
        model_actions = []
        
        for i in range(self.n_parallel):
            model_action = self.action_space.sample()
            model_obs = self.latest_models_obs[agent_num][i]
            if self.models[agent_num] is not None and model_obs is not None:
                model_action, _ = self.models[agent_num].predict(model_obs, deterministic=True)
            model_actions.append(model_action)
            
        return model_actions
    
    def get_model_actions(self):
        model_actions = []
        for i in range(self.agents_per_env):
            model_action = self.get_model_action(i)
            model_actions += model_action
        return model_actions
    
    @property 
    def num_envs(self) -> int:
        return self.n_parallel
    
    def env_is_wrapped(self, wrapper_class=None, indices=None) -> List[bool]:
        return [False] * (self.n_parallel)

    def env_method(self):
        raise NotImplementedError()

    def get_attr(self, attr_name: str, indices = None) -> List[Any]:
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

# Notes:
# obs = [array * agents_per_env * n_parallel]
# rewards = [float * agents_per_env * n_parallel]
# dones = [bool * agents_per_env * n_parallel]


