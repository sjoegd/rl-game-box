import gymnasium
import pygame
from games.battle_tanks.env import BattleTanksEnv
from games.tron_light_cycles.env import TronLightCyclesEnv

# env = gymnasium.make('TronLightCycles-v0', render_mode='human', player2_mode='human')
env = TronLightCyclesEnv(render_mode='human', player2_mode='human')
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
