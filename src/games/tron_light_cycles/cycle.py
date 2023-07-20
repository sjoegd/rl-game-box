from math import cos, degrees, radians, sin
import pygame
import pymunk

from games.tron_light_cycles.settings.constants import COLLISION_TYPE_CYCLE

from .trail import Trail

from typing import TYPE_CHECKING
if TYPE_CHECKING:
    from .env import TronLightCyclesEnv

class Cycle(pygame.sprite.Sprite):
    
    def __init__(self, x, y, color: str, mask, enemy_mask, env: 'TronLightCyclesEnv'):
        super().__init__()
        
        self.env = env
        self.color = color
        self.base_image = self.env.cycle_images[color]
        self.image = self.base_image
        self.rect = self.base_image.get_rect(center=(x, y))
        
        self.width = self.base_image.get_width()
        self.height = self.base_image.get_height()
        
        self.mask = mask
        self.enemy_mask = enemy_mask
        
        self.body = pymunk.Body(body_type=pymunk.Body.DYNAMIC)
        self.body.position = (x, y)
        self.shape = pymunk.Poly.create_box(self.body, size=(self.width, self.height*0.8))
        self.shape.density = 1
        self.shape.collision_type = COLLISION_TYPE_CYCLE
        self.shape.filter = pymunk.ShapeFilter(mask=mask)
        self.shape.sprite = self
        
        self.env.space.add(self.body, self.shape)
        
        self.speed = 5
        self.turn_speed = radians(4)
        
        self.trail = Trail(self, self.env)
        self.trail_cooldown_max = 6 # Lower is cleaner, higher is efficient
        self.trail_cooldown = 0
        
        self.forward = True
        self.right = False
        self.left = False
        
        self.is_death = False
    
    def update(self):
        self.move()
        self.update_trail()
    
    def move(self):
        dx = 0
        dy = 0
        d_angle = 0
        
        corrected_angle = self.body.angle
        
        if self.forward:
            dx -= self.speed * cos(corrected_angle)
            dy -= self.speed * sin(corrected_angle) 
            
            if self.right:
                d_angle += self.turn_speed
            if self.left:
                d_angle -= self.turn_speed
        
        self.body.position += (dx, dy)
        self.body.angle += d_angle
    
    def update_trail(self):
        if self.trail_cooldown > 0:
            self.trail_cooldown -= 1
            
        if self.trail_cooldown == 0:
            self.trail_cooldown = self.trail_cooldown_max
            x = self.body.position.x + cos(self.body.angle) * ((self.width // 2) - self.speed*self.trail_cooldown_max//2)
            y = self.body.position.y + sin(self.body.angle) * ((self.width // 2) - self.speed*self.trail_cooldown_max//2)
            self.trail.activate_last_line() # always before adding position
            self.trail.add_position((x, y))
    
    def die(self):
        self.is_death = True
        self.trail.remove_trail()
        self.kill()
        self.env.space.remove(self.body, self.shape)
    
    def update_render(self):
        self.image = pygame.transform.rotate(self.base_image, -degrees(self.body.angle))
        self.rect = self.image.get_rect(center=self.body.position)
    
    def draw(self, surface: pygame.Surface):
        surface.blit(self.image, self.rect)