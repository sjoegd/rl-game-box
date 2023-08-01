import pygame
from stable_baselines3 import PPO
from games.battle_tanks.env import BattleTanksEnv
from games.tron_light_cycles.env import TronLightCyclesEnv
from games.util.util import create_frameskip_env

# agent = PPO.load("models/TronLightCycles-v0/PPO/PPO_0")
# base_env = TronLightCyclesEnv(render_mode='human', player2_mode='agent', player2_agent=agent)

base_env = BattleTanksEnv(render_mode='human', player2_mode='human', render_in_step=True)
env = create_frameskip_env(base_env)

env.reset()
running = True
while running:
    _, _, terminated, _, _ = env.step(base_env.human_action)
    
    if terminated:
        env.reset()
    
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False

env.close()
