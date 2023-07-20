from math import degrees, radians
import pygame
import pymunk

from .explosion import Explosion

from .settings.constants import ROCKET_COLLISION_TYPE, ROCKET_DAMAGE, ROCKET_SPEED

from typing import TYPE_CHECKING
if TYPE_CHECKING:
    from .tank import Tank

class Rocket(pygame.sprite.Sprite):
    
    def __init__(self, x, y, angle, owner: 'Tank'):
        super().__init__()
        
        self.owner = owner
        self.env = owner.env
        self.color = owner.color
        
        self.base_image = self.env.rocket_images[self.color]
        self.rect = self.base_image.get_rect(center=(x, y))
        
        self.damage = ROCKET_DAMAGE
        self.speed = ROCKET_SPEED
        self.angle = angle
        self.velocity = pymunk.Vec2d(1, 0).rotated(angle-radians(90)) * self.speed
        
        self.body = pymunk.Body(body_type=pymunk.Body.DYNAMIC)
        self.body.position = (x, y)
        self.body.angle = angle
        self.shape = pymunk.Poly.create_box(self.body, size=(self.base_image.get_width(), self.base_image.get_height()))
        self.shape.density = 1
        self.shape.collision_type = ROCKET_COLLISION_TYPE
        self.shape.filter = pymunk.ShapeFilter(
            categories=pymunk.ShapeFilter.ALL_CATEGORIES() ^ self.owner.mask,
            mask=self.owner.rocket_mask
        )
        self.shape.sprite = self
        
        self.env.space.add(self.body, self.shape)
        self.env.rockets.add(self)
    
    def explode(self):
        self.kill()
        self.env.space.remove(self.body, self.shape)
        if self.env.render_mode == "human":
            Explosion(self.body.position.x, self.body.position.y, "rocket", self.env)
    
    def update(self):
        self.body.angular_velocity = 0
        self.body.angle = self.angle
        self.body.position += self.velocity 
    
    def update_render(self):
        self.image = pygame.transform.rotate(self.base_image, -degrees(self.angle))
        self.rect = self.image.get_rect(center=self.body.position)
    
    def draw(self, surface: pygame.Surface):
        surface.blit(self.image, self.rect)