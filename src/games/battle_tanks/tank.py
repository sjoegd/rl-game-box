import math
import pygame
import pymunk

from .settings.constants import TANK_ROTATE_SPEED, TANK_SPEED, TURRET_BODY_OFFSET, TURRET_ROTATE_SPEED

from typing import TYPE_CHECKING
if TYPE_CHECKING:
    from .env import BattleTanksEnv

class Tank(pygame.sprite.Sprite):
    
    def __init__(self, x, y, env: 'BattleTanksEnv'):
        
        self.env = env
        
        self.body_base_image = env.body_image
        self.turret_base_image = env.turret_image
        
        self.turret_body_offset = TURRET_BODY_OFFSET
        
        self.main_body = pymunk.Body(body_type=pymunk.Body.DYNAMIC)
        self.main_body.position = (x, y)
        self.main_shape = pymunk.Poly.create_box(
            self.main_body, 
            size=(self.body_base_image.get_width(), self.body_base_image.get_height())
        )
        self.main_shape.density = 1
        
        self.turret_body = pymunk.Body(body_type=pymunk.Body.KINEMATIC)
        self.turret_body.position = (x, y) + self.turret_body_offset
        self.turret_shape = pymunk.Poly.create_box(self.turret_body, size=(self.turret_base_image.get_width(), self.turret_base_image.get_height()))
        self.turret_shape.density = 1
        self.turret_shape.filter = pymunk.ShapeFilter(categories=0)
        
        self.env.space.add(self.main_body, self.main_shape)
        self.env.space.add(self.turret_body, self.turret_shape)
        
        self.forward = False
        self.backward = False
        self.right = False
        self.left = False
        self.turret_right = False
        self.turret_left = False
        self.shooting = False
        
        self.speed = TANK_SPEED
        self.rotate_speed = TANK_ROTATE_SPEED
        self.turret_rotate_speed = TURRET_ROTATE_SPEED
    
    def update(self):
        self.move()
        self.update_turret_position()

    def move(self):
        dx = 0
        dy = 0
        d_main_angle = 0
        d_turret_angle = 0
        
        move_angle = self.main_body.angle + (math.pi / 2)
        
        if self.forward and not self.backward:
            dx -= self.speed * math.cos(move_angle)
            dy -= self.speed * math.sin(move_angle)
        
        if self.backward and not self.forward:
            dx += self.speed * math.cos(move_angle)
            dy += self.speed * math.sin(move_angle)
        
        if self.right:
            d_main_angle += self.rotate_speed
            d_turret_angle += self.rotate_speed
        
        if self.left:
            d_main_angle -= self.rotate_speed
            d_turret_angle -= self.rotate_speed
        
        if self.turret_right:
            d_turret_angle += self.turret_rotate_speed
        
        if self.turret_left:
            d_turret_angle -= self.turret_rotate_speed
        
        self.main_body.position += (dx, dy)
        self.main_body.angle += d_main_angle
        self.turret_body.angle += d_turret_angle
    
    def shoot(self):
        pass
    
    def update_turret_position(self):
        offset = self.turret_body_offset.rotated(self.main_body.angle)
        position = self.main_body.position + offset
        self.turret_body.position = position
    
    def update_render(self):
        self.main_image = pygame.transform.rotate(self.body_base_image, -math.degrees(self.main_body.angle))
        self.turret_image = pygame.transform.rotate(self.turret_base_image, -math.degrees(self.turret_body.angle))
        self.main_rect = self.main_image.get_rect(center=self.main_body.position)
        self.turret_rect = self.turret_image.get_rect(center=self.turret_body.position)
        
    def draw(self, screen):
        screen.blit(self.main_image, self.main_rect)
        screen.blit(self.turret_image, self.turret_rect)