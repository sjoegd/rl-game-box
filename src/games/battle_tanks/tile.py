import pygame
import pymunk

from .settings.constants import TILE_COLLISION_TYPE, TILE_MASK

from typing import TYPE_CHECKING
if TYPE_CHECKING:
    from .env import BattleTanksEnv

class Tile(pygame.sprite.Sprite):
    
    def __init__(self, x: float, y: float, image: pygame.Surface, is_wall: bool, env: 'BattleTanksEnv'):
        super().__init__()
        
        self.env = env
        
        self.image = image
        self.rect = self.image.get_rect(topleft=(x, y))
        
        self.is_wall = is_wall
        if is_wall:
            self.body = pymunk.Body(body_type=pymunk.Body.STATIC)
            self.body.position = x + (self.image.get_width() // 2), y + (self.image.get_height() // 2)
            self.shape = pymunk.Poly.create_box(self.body, size=(self.image.get_width(), self.image.get_height()))
            self.shape.collision_type = TILE_COLLISION_TYPE
            self.shape.filter = pymunk.ShapeFilter(mask=TILE_MASK)
            self.env.space.add(self.body, self.shape)