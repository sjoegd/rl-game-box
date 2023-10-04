import gymnasium as gym
import numpy as np
from stable_baselines3 import PPO
from godot_rl.wrappers.stable_baselines_wrapper import StableBaselinesGodotEnv

# TODO: Vectorize
# Find possible other ways to do this
# Check if speedup doesn't break things (see if steps are still correct)

# Currently only supports a single environment with 2 players
class SelfPlayGodotEnv(gym.Env):
    def __init__(
        self,
        env: StableBaselinesGodotEnv
    ):
        self.env = env
        self.model = None
        self.observation_space = env.observation_space.spaces["obs"]
        self.action_space = env.action_space

    def set_model(self, model: PPO):
        self.model = model
    
    def step(self, action: np.ndarray):
        model_action = self.get_model_action()
        
        obs, rewards, done, info = self.env.step(np.array([action, model_action]))
        
        obs = obs["obs"]
        step_obs = np.array(obs[0], np.float32)
        self.latest_model_obs = np.array(obs[1], np.float32)
        
        return step_obs, rewards[0], (done[0] or done[1]), False, {}
    
    def reset(self, seed=0):
        obs = self.env.reset()["obs"]
        self.latest_model_obs = np.array(obs[1], np.float32)
        return np.array(obs[0], np.float32), {}
    
    def get_model_action(self):
        model_action = self.action_space.sample()
        if self.latest_model_obs is not None and self.model is not None:
            model_action, _ = self.model.predict(self.latest_model_obs, deterministic=True)
        return model_action

env = StableBaselinesGodotEnv(
    env_path="games/Soccer/build/soccer_train.exe",
    show_window=True,
    speedup=10
)
env = SelfPlayGodotEnv(env)

agent = PPO(policy="MlpPolicy", env=env)
env.set_model(agent)

past_agents = []
max_past_agents = 10
total_timesteps = 1_000_000
total_iterations = 100
steps_per_iteration = total_timesteps // total_iterations

for i in range(total_iterations):
    print("Iteration:", i)
    agent.learn(steps_per_iteration, reset_num_timesteps=False)
    agent.save("models/soccer_ppo")
    new_agent = PPO.load("models/soccer_ppo")
    past_agents.append(new_agent)
    if len(past_agents) > max_past_agents:
        past_agents.pop(0)
    env.set_model(past_agents[np.random.randint(len(past_agents))])

agent.save("models/soccer_ppo")
env.close()


