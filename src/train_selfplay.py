import sys
import random
import os

from stable_baselines3 import PPO
from stable_baselines3.common.vec_env import SubprocVecEnv
from stable_baselines3.common.env_util import make_vec_env
from stable_baselines3.common.callbacks import BaseCallback, EveryNTimesteps
from stable_baselines3.common.atari_wrappers import MaxAndSkipEnv

import gymnasium
from games.tron_light_cycles.env import TronLightCyclesEnv  # noqa: F401

class SelfPlaySaveCallback(BaseCallback):
    
    def __init__(self, save_model):
        super(SelfPlaySaveCallback, self).__init__(0)
        self.save_model = save_model
    
    def _on_step(self):
        self.save_model()
        return True

class SelfPlayUpdateCallback(BaseCallback):
    
    def __init__(self, update_env):
        super(SelfPlayUpdateCallback, self).__init__(0)
        self.update_env = update_env
    
    def _on_step(self):
        self.update_env()
        return False

def make_selfplay_env(env_id="", player2_agent_choice=None):
    env = gymnasium.make(env_id, render_mode=None, player2_mode='agent', player2_agent_choice=player2_agent_choice)
    return MaxAndSkipEnv(env, skip=env.frame_skip)

if __name__ == "__main__":
    
    if len(sys.argv) != 5:
        raise Exception("Usage: python train_selfplay.py <env_id> <algorithm> <iteration> <resume>")

    env_id = sys.argv[1]
    algorithm = sys.argv[2]
    iteration = sys.argv[3]
    resume = sys.argv[4] == 'True'

    if algorithm not in ['PPO']:
        raise Exception("Currently only supporting PPO")
    
    file_path = f"models/{env_id}/{algorithm}/{algorithm}_{iteration}"
    
    env_n = os.cpu_count()
    
    env = make_vec_env(
        make_selfplay_env,
        n_envs=env_n,
        seed=0,
        vec_env_cls=SubprocVecEnv,
        env_kwargs={'env_id': env_id}
    )
    
    total_learning_steps = 50_000_000
    save_steps           = 10_000
    update_steps         = 50_000
    
    learning_iterations  = total_learning_steps // update_steps
    learning_memory_size = 50
    learning_memory      = []
    
    if algorithm == 'PPO':
        if resume:
            model = PPO.load(file_path, env=env, device='cpu')
        else:
            model = PPO(
                'MlpPolicy',
                env=env,
                n_steps=1000,
                batch_size=250,
                ent_coef=0.01,
                gae_lambda=0.95,
                clip_range=0.2,
                learning_rate=1e-5,
                n_epochs=32,
                gamma=0.99,
                max_grad_norm=0.5,
                device='cpu',
                verbose=1
            )
    
    def save_model():
        global learning_memory
        
        model.save(file_path)
        print(f"# --- Saved Model At: {file_path} --- #")
        
        if algorithm == 'PPO':
            new_model = PPO.load(file_path)
        
        if len(learning_memory) < learning_memory_size:
            learning_memory.append(new_model)
        elif 1/learning_memory_size > random.random():
            learning_memory[random.randrange(0, learning_memory_size)] = new_model
            print("# --- Updated Learning Memory --- #")
            
        print(f"# --- Memory Length: {len(learning_memory)}/{learning_memory_size} --- #")
    
    def update_env():
        global env
        
        env.close()
        
        env = make_vec_env(
            make_selfplay_env,
            n_envs=env_n,
            seed=0,
            vec_env_cls=SubprocVecEnv,
            env_kwargs={'env_id': env_id, 'player2_agent_choice': learning_memory}
        )
        
        model.set_env(env)
        
        print(f"# --- Updated {env_n} Environments --- #")
    
    save_cb   = SelfPlaySaveCallback(save_model)
    save_n_steps_cb   = EveryNTimesteps(n_steps=save_steps, callback=save_cb)
    
    update_cb  = SelfPlayUpdateCallback(update_env)
    update_n_steps_cb  = EveryNTimesteps(n_steps=update_steps, callback=update_cb)
    
    save_model()
    for i in range(learning_iterations):
        model.learn(total_timesteps=total_learning_steps, reset_num_timesteps=False, callback=[save_n_steps_cb, update_n_steps_cb])
        print(f"# --- Finished iteration {i+1} of {learning_iterations} --- #")
    
    model.save(file_path)
    print(f"# --- Finished training {algorithm} for {total_learning_steps} steps --- #")