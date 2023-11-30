from typing import Any, List
import numpy as np
from stable_baselines3 import PPO
from godot_rl.wrappers.stable_baselines_wrapper import StableBaselinesGodotEnv
from stable_baselines3.common.vec_env.base_vec_env import VecEnv
from godot_rl.core.godot_env import GodotEnv

class NewSelfPlayGodotEnvAsync(VecEnv):
    def __init__(
        self,
        env_path: str = None,
        port=GodotEnv.DEFAULT_PORT,
        agents_per_env: int = 2,
        n_parallel: int = 1,
        games_per_env: int = 1,
        speedup: int = 1,
        action_repeat: int = 4,
        show_window: bool = False,
    ):
        self.env = StableBaselinesGodotEnv(
            env_path=env_path,
            port=port,
            n_parallel=n_parallel,
            speedup=speedup,
            show_window=show_window,
            **{
                "action_repeat": action_repeat
            }
        )
        self.observation_space = self.env.observation_space.spaces["obs"]
        self.action_space = self.env.action_space
        self.n_parallel = n_parallel
        self.agents_per_env = agents_per_env
        self.games_per_env = games_per_env
        self.env_model_handlers = [EnvModelHandler(self, self.agents_per_env, self.games_per_env) for _ in range(self.n_parallel)]

    def choose_models(self, model_paths: list[str]):
        for env_model_handler in self.env_model_handlers:
            env_model_handler.choose_model(model_paths)
    
    def step(self, actions: np.ndarray):
        # Collect all actions
        all_model_actions = []
        
        for i in range(self.n_parallel):
            for j in range(self.games_per_env):
                all_model_actions.append(actions[j + i*self.games_per_env])
                all_model_actions += self.env_model_handlers[i].get_model_actions(j)
        
        # Step the environment
        obs, rewards, dones, _ = self.env.step(np.array(all_model_actions))
        obs = obs["obs"]
        
        # Parse the step
        main_obs, main_rewards, main_dones, side_obs = self.parse_step(obs, rewards, dones)
        for i in range(self.n_parallel):
            self.env_model_handlers[i].set_latest_obs(side_obs[i])
        
        return main_obs, main_rewards, main_dones, [{} for _ in range(self.num_envs)]
        
    def parse_step(self, obs: np.ndarray, rewards: np.ndarray, dones: np.ndarray):
        main_obs = []
        main_rewards = []
        main_dones = []
        side_obs = [[] for _ in range(self.n_parallel)]
        
        for i in range(len(obs)):
            if i % self.agents_per_env == 0:
                main_obs.append(obs[i])
                main_rewards.append(rewards[i])
                main_dones.append(dones[i])
            else:
                side_obs[i // (self.games_per_env*self.agents_per_env)].append(obs[i])
            
        return np.array(main_obs), np.array(main_rewards), np.array(main_dones), np.array(side_obs)
    
    def parse_obs(self, obs: np.ndarray):
        main_obs = []
        side_obs = [[] for _ in range(self.n_parallel)]
        
        for i in range(len(obs)):
            if i % self.agents_per_env == 0:
                main_obs.append(obs[i])
            else:
                side_obs[i // (self.games_per_env*self.agents_per_env)].append(obs[i])
        
        return np.array(main_obs), np.array(side_obs)
    
    def reset(self, seed=0):
        obs = self.env.reset()["obs"]
        main_obs, side_obs = self.parse_obs(obs)
        for i in range(self.n_parallel):
            self.env_model_handlers[i].set_latest_obs(side_obs[i])
        return main_obs

    def close(self):
        self.env.close()
    
    @property
    def num_envs(self) -> int:
        return self.n_parallel * self.games_per_env
    
    def env_is_wrapped(self, wrapper_class=None, indices=None) -> List[bool]:
        return [False] * self.num_envs

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
    
class EnvModelHandler:
    
    def __init__(
        self,
        env: NewSelfPlayGodotEnvAsync,
        agents_per_env: int,
        games_per_env: int
    ):
        self.env = env
        self.agents_per_env = agents_per_env - 1
        self.games_per_env = games_per_env
        self.model = None
        self.latest_obs = [None for _ in range(self.agents_per_env*self.games_per_env)]
    
    def set_model(self, model_path: str):
        self.model = PPO.load(model_path)
        print(f"Loaded model {model_path}")
    
    def choose_model(self, model_paths: list[str]):
        self.set_model(np.random.choice(model_paths))
    
    def set_latest_obs(self, obs: np.ndarray):
        self.latest_obs = obs
    
    def get_model_action(self, i: int):
        model_action = self.env.action_space.sample()
        model_obs = self.latest_obs[i]
        if self.model and model_obs:
            model_action, _ = self.model.predict(model_obs, deterministic=True)
        return model_action
    
    def get_model_actions(self, game_n: int):
        model_actions = []
        for i in range(self.agents_per_env):
            model_actions.append(self.get_model_action(game_n + i))
        return model_actions