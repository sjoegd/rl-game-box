import pygame
import pymunk
from pymunk import pygame_util

from .tank import Tank
from .settings.constants import TANK_SCALE

from games.util.util import scale_surface

class BattleTanksEnv:
    
    def __init__(self):
        
        pygame.init()
        
        self.screen = pygame.display.set_mode((1280, 720))
        self.clock = pygame.time.Clock()
        
        self.space = pymunk.Space()
        self.draw_util = pygame_util.DrawOptions(self.screen)
        
        self.body_image = pygame.image.load("assets/battle-tanks/images/tanks/body_red.png")
        self.body_image = scale_surface(self.body_image, TANK_SCALE).convert_alpha()
        self.turret_image = pygame.image.load("assets/battle-tanks/images/tanks/turret_red_with_offset.png")
        self.turret_image = scale_surface(self.turret_image, TANK_SCALE).convert_alpha()
        
        self.tank = Tank(400, 300, self)
    
    def input(self):
        keys = pygame.key.get_pressed()
        self.tank.forward = keys[pygame.K_w]
        self.tank.backward = keys[pygame.K_s]
        self.tank.right = keys[pygame.K_d]
        self.tank.left = keys[pygame.K_a]
        self.tank.turret_right = keys[pygame.K_RIGHT]
        self.tank.turret_left = keys[pygame.K_LEFT]
    
    def step(self):
        self.space.step(1/60)
        self.tank.update()
    
    def reset(self):
        pass
    
    def render(self):
        self.screen.fill((255, 255, 255))
        self.space.debug_draw(self.draw_util)
        self.tank.update_render()
        self.tank.draw(self.screen)
        pygame.display.flip()
        self.clock.tick(60)
    
    def close(self):
        pygame.quit()