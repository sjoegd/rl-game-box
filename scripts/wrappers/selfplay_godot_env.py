from pathlib import Path
import numpy as np
from stable_baselines3 import PPO
from godot_rl.wrappers.stable_baselines_wrapper import StableBaselinesGodotEnv
from stable_baselines3.common.vec_env.base_vec_env import VecEnv
from godot_rl.core.godot_env import GodotEnv

# TODO:
# - Add support for RecurrentPPO

"""
A custom wrapper around the GodotEnv that allows
agents to play against other models with multiple parallel envs and
multiple games instances per env.
"""
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
        action_repeat: int = 1,
    ):

        self.env = StableBaselinesGodotEnv(
            env_path=env_path,
            n_parallel=n_parallel,
            show_window=show_window,
            speedup=speedup,
            port=port,
            **{
                "action_repeat": action_repeat,
            },
        )

        self.observation_space = self.env.observation_space.spaces["obs"]
        self.action_space = self.env.action_space
        self.n_parallel = n_parallel
        self.agents_per_env = agents_per_env
        self.games_per_env = games_per_env
        self.agents = [None] * (self.agents_per_env - 1)
        self.previous_obs = [None] * (self.num_envs * self.agents_per_env)

    def set_models(self, models: list[Path]):
        for i, path in enumerate(models):
            self.agents[i] = PPO.load(path)
            print(f"Loaded model {path} for agent {i}")

    def step(self, step_actions: np.ndarray):

        step_actions = step_actions.tolist()
        all_actions = [None] * (self.num_envs * self.agents_per_env)

        for i, ob in enumerate(self.previous_obs):
            if i % self.agents_per_env == 0:
                # Take step action
                all_actions[i] = step_actions.pop(0)
            else:
                # Take agent action
                all_actions[i] = self.get_agent_action(
                    ob, (i % self.agents_per_env) - 1
                )

        obs, rewards, dones, _ = self.env.step(np.array(all_actions))
        obs = obs["obs"]
        self.previous_obs = obs

        step_obs, step_rewards, step_dones = self.parse_step(obs, rewards, dones)

        return step_obs, step_rewards, step_dones, [{} for _ in range(self.num_envs)]

    def get_agent_action(self, ob: np.ndarray, agent_i: int):
        agent = self.agents[agent_i]
        action = self.action_space.sample()
        if agent is not None and ob is not None:
            action, _ = agent.predict(ob, deterministic=True)
        return action

    def parse_step(
        self, obs: np.ndarray, rewards: np.ndarray = None, dones: np.ndarray = None
    ):
        step_obs = []
        step_rewards = []
        step_dones = []

        for i, ob in enumerate(obs):
            if i % self.agents_per_env == 0:
                step_obs.append(ob)
                if rewards is not None:
                    step_rewards.append(rewards[i])
                if dones is not None:
                    step_dones.append(dones[i])

        return np.array(step_obs), np.array(step_rewards), np.array(step_dones)

    def reset(self, seed=0):
        obs = self.env.reset()["obs"]
        self.previous_obs = obs
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

    def get_attr(self, attr_name: str, indices=None) -> list[any]:
        if attr_name == "render_mode":
            return [None for _ in range(self.num_envs)]
        raise NotImplementedError()

    def seed(self, seed=None):
        raise NotImplementedError()

    def set_attr(self):
        raise NotImplementedError()

    def step_async(self, actions: np.ndarray) -> None:
        self.results = self.step(actions)

    def step_wait(self):
        return self.results

# Test
if __name__ == "__main__":
    env = SelfplayGodotEnv(
        env_path="games/Test/builds/test.exe",
        n_parallel=4,
        agents_per_env=4,
        games_per_env=4,
    )
    obs = env.reset()

    for _ in range(100):
        env.step(np.array([np.zeros(env.action_space.shape)] * env.num_envs))

    env.close()