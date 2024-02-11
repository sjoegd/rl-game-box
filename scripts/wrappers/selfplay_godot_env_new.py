from pathlib import Path
from itertools import chain
import numpy as np
from stable_baselines3 import PPO
from godot_rl.wrappers.stable_baselines_wrapper import StableBaselinesGodotEnv
from stable_baselines3.common.vec_env.base_vec_env import VecEnv
from godot_rl.core.godot_env import GodotEnv

class SelfplayGodotEnv(VecEnv):
    
    def __init__(
        self,
        env_path: str = "",
        agents_per_env: int = 1,
        games_per_env: int = 1,
        n_parallel: int = 1,
        show_window: bool = False,
        speedup: int = 1,
        port=GodotEnv.DEFAULT_PORT,
        action_repeat: int = 1
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
        self.model_handler = SelfplayModelHandler(self, agents_per_env-1)
    
    def set_models(self, models: list[Path]):
        for agent in range(self.model_handler.num_agents):
            self.model_handler.set_model(agent, models[agent])
    
    def step(self, step_actions: np.ndarray):
        
        agent_actions = []
        
        for agent in range(self.model_handler.num_agents):
            agent_actions.append(self.model_handler.get_agent_actions(agent))
        
        all_actions = []
        
        for a in range(len(step_actions)):
            all_actions.append(step_actions[a])
            for agent in range(self.model_handler.num_agents):
                all_actions.append(agent_actions[agent][a])
        
        all_actions = np.array(all_actions)
        
        obs, rewards, dones, _ = self.env.step(all_actions)
        obs = obs["obs"]
        
        step_obs, step_rewards, step_dones = self.parse_step(obs, rewards, dones)
        
        return step_obs, step_rewards, step_dones, [{} for _ in range(self.num_envs)]
    
    def parse_step(self, obs: np.ndarray, rewards: np.ndarray = None, dones: np.ndarray = None):
        step_obs = []
        step_rewards = []
        step_dones = []
        agent_obs = [[] for _ in range(self.model_handler.num_agents)]

        for i in range(len(obs)):
            agent = i % self.agents_per_env
            if agent == 0:
                step_obs.append(obs[i])
                if rewards is not None:
                    step_rewards.append(rewards[i])
                if dones is not None:
                    step_dones.append(dones[i])
            else:
                agent_obs[agent-1].append(obs[i])
        
        for agent in range(self.model_handler.num_agents):
            self.model_handler.set_agent_obs(agent, np.array(agent_obs[agent]))
        
        return np.array(step_obs), np.array(step_rewards), np.array(step_dones)

    def reset(self, seed=0):
        obs = self.env.reset()["obs"]
        step_obs, _, _ = self.parse_step(obs)
        return step_obs
    
    def close(self):
        self.env.close()
    
    @property
    def num_envs(self):
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
    
    def __init__(self, env: SelfplayGodotEnv, agents: int):
        self.env = env
        self.agents = agents
        self.models = [None for _ in range(agents)]
        self.agent_obs = [None for _ in range(agents)]
    
    @property
    def num_agents(self):
        return self.agents
    
    def set_model(self, agent: int, model_path: str):
        self.models[agent] = PPO.load(model_path)
        print(f"Loaded model {model_path} for agent {agent}")
    
    def set_agent_obs(self, agent: int, obs: np.ndarray):
        self.agent_obs[agent] = obs
    
    def get_agent_actions(self, agent: int):
        actions = []
        for obs in self.agent_obs[agent]:
            actions.append(self.get_agent_action(agent, obs))
        return actions
    
    def get_agent_action(self, agent: int, obs: np.ndarray = None):
        model = self.models[agent]
        if model is None or obs is None:
            return self.env.action_space.sample()
        action, _ = model.predict(obs, deterministic=True)
        return action