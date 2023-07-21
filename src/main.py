import pygame
from stable_baselines3 import PPO
from games.battle_tanks.env import BattleTanksEnv
from games.tron_light_cycles.env import TronLightCyclesEnv

# agent = PPO.load("models/TronLightCycles-v0/PPO/PPO_0")
# env = TronLightCyclesEnv(render_mode='human', player2_mode='agent', player2_agent=agent)

env = BattleTanksEnv(render_mode='human', player2_mode='human')

env.reset()
running = True
while running:
    _, _, terminated, _, _ = env.step(env.human_action)
    
    env.render()
    
    if terminated:
        env.reset()
    
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False

env.close()
