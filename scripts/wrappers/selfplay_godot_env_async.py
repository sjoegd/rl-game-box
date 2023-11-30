from typing import Any, List
import numpy as np
from stable_baselines3 import PPO
from godot_rl.wrappers.stable_baselines_wrapper import StableBaselinesGodotEnv
from stable_baselines3.common.vec_env.base_vec_env import VecEnv
from godot_rl.core.godot_env import GodotEnv

class SelfPlayGodotEnvAsync(VecEnv):
    def __init__(
        self,
        env_path: str = None,
        agents_per_env: int = 2,
        show_window: bool = False,
        speedup: int = 1,
        port=GodotEnv.DEFAULT_PORT,
        n_parallel: int = 1,
        action_repeat: int = 4
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
        self.env_models = [SelfPlayEnvModel(self, self.agents_per_env) for _ in range(self.n_parallel)]

    def choose_models(self, model_paths: list[str]):
        for env_model in self.env_models:
            env_model.choose_models(model_paths)
    
    def step(self, actions: np.ndarray):
        # Get and combine actions from all models
        total_model_actions = []
        for i in range(self.n_parallel):
            total_model_actions.append(actions[i])
            total_model_actions += self.env_models[i].get_model_actions()
        
        # Step the environment
        obs, rewards, dones, _ = self.env.step(np.array(total_model_actions))
        obs = obs["obs"]
        
        # Get information for main model
        step_obs = self.parse_obs(obs)
        step_rewards = []
        step_dones = []
        for i in range(self.n_parallel):
            step_rewards.append(rewards[i * (self.agents_per_env + 1)])
            # Check whether any agent of the env is done
            env_dones = dones[i * (self.agents_per_env + 1) : (i + 1) * (self.agents_per_env + 1)]
            step_dones.append(True in env_dones)
        step_rewards = np.array(step_rewards)
        step_dones = np.array(step_dones)
        
        return step_obs, step_rewards, step_dones, [{} for _ in range(self.n_parallel)]
    
    def reset(self, seed=0):
        obs = self.env.reset()["obs"]
        return self.parse_obs(obs)
    
    def close(self):
        self.env.close()
    
    def parse_obs(self, obs):
        step_obs = []
        for i in range(self.n_parallel):
            step_obs.append(obs[i * (self.agents_per_env + 1)])
        
        for i in range(self.n_parallel):
            for j in range(self.agents_per_env):
                self.env_models[i].set_latest_model_obs(j, obs[(i * (self.agents_per_env + 1)) + (j + 1)])
        
        return np.array(step_obs)
    
    @property 
    def num_envs(self) -> int:
        return self.n_parallel
    
    def env_is_wrapped(self, wrapper_class=None, indices=None) -> List[bool]:
        return [False] * self.n_parallel

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

# TODO: Rename to something better
class SelfPlayEnvModel:
    
    def __init__(self, env: SelfPlayGodotEnvAsync, agents_per_env: int):
        self.env = env
        self.agents_per_env = agents_per_env
        self.models = [None for _ in range(agents_per_env)]
        self.latest_models_obs = [None for _ in range(agents_per_env)]
    
    def set_model(self, agent_n: int, model_path: str):
        self.models[agent_n] = PPO.load(model_path)
        print(f"Loaded model {model_path} for agent {agent_n}")
    
    def choose_model(self, agent_n: int, model_paths: list[str]):
        model_path = model_paths[np.random.randint(len(model_paths))]
        self.set_model(agent_n, model_path)
    
    def choose_models(self, model_paths: list[str]):
        for i in range(self.agents_per_env):
            self.choose_model(i, model_paths)
    
    def set_latest_model_obs(self, agent_n: int, obs: np.ndarray):
        self.latest_models_obs[agent_n] = obs
    
    def get_model_action(self, agent_n: int):
        model_action = self.env.action_space.sample()
        model_obs = self.latest_models_obs[agent_n]
        model = self.models[agent_n]
        if model is not None and model_obs is not None:
            model_action, _ = model.predict(model_obs, deterministic=True)
        return model_action
    
    def get_model_actions(self):
        model_actions = []
        for i in range(self.agents_per_env):
            model_action = self.get_model_action(i)
            model_actions.append(model_action)
        return model_actions
