# ENV TESTING

import pygame
from games.battle_tanks.env import BattleTanksEnv

env = BattleTanksEnv()

running = True
while running:
    
    env.input()
    env.step()
    env.render()
    
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False

env.close()
