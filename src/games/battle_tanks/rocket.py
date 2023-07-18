from math import degrees, radians
import pygame
import pymunk

from .settings.constants import ROCKET_COLLISION_TYPE, ROCKET_SPEED

from typing import TYPE_CHECKING
if TYPE_CHECKING:
    from .tank import Tank

class Rocket(pygame.sprite.Sprite):
    
    def __init__(self, x, y, angle, owner: 'Tank'):
        super().__init__()
        
        self.speed = ROCKET_SPEED
        
        self.owner = owner
        self.env = owner.env
        self.color = owner.color
        self.base_image = self.env.rocket_images[self.color]
        self.rect = self.base_image.get_rect(center=(x, y))
        self.angle = angle
        self.velocity = pymunk.Vec2d(1, 0).rotated(angle-radians(90))
        
        self.body = pymunk.Body(body_type=pymunk.Body.DYNAMIC)
        self.body.position = (x, y)
        self.body.angle = angle
        self.shape = pymunk.Poly.create_box(self.body, size=(self.base_image.get_width(), self.base_image.get_height()))
        self.shape.density = 1
        self.shape.collision_type = ROCKET_COLLISION_TYPE
        self.shape.sprite = self
        
        self.env.space.add(self.body, self.shape)
        self.env.rockets.add(self)
        
    def update(self):
        self.body.angular_velocity = 0
        self.body.angle = self.angle
        self.body.position += self.velocity * self.speed
    
    def update_render(self):
        self.image = pygame.transform.rotate(self.base_image, -degrees(self.angle))
        self.rect = self.image.get_rect(center=self.body.position)
    
    def draw(self, surface: pygame.Surface):
        surface.blit(self.image, self.rect)