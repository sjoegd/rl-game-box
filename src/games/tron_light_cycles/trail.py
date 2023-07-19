
from math import atan2, degrees
import pygame

from typing import TYPE_CHECKING

import pymunk

from games.tron_light_cycles.settings.constants import COLLISION_TYPE_TRAIL
if TYPE_CHECKING:
    from .env import TronLightCyclesEnv
    from .cycle import Cycle

class Trail(pygame.sprite.Sprite):
    
    def __init__(self, owner: 'Cycle', env: 'TronLightCyclesEnv'):
        super().__init__()
        self.env = env
        self.owner = owner
        self.color = owner.color
        self.base_image = self.env.trail_images[self.color]
        self.positions = []
        self.lines = []
        self.unactive_filter = pymunk.ShapeFilter(categories=0)
        self.activation_filter = pymunk.ShapeFilter(categories=pymunk.ShapeFilter.ALL_CATEGORIES())
        self.env.trails.add(self)
    
    def activate_last_line(self):
        if len(self.lines) > 1:
            last_line = self.lines[-1]
            last_line[0].filter = self.activation_filter
    
    def add_position(self, position):
        if len(self.positions) > 1:
            last_position = self.positions[-1]
            self.create_line(last_position, position)
        
        self.positions.append(position)
    
    def create_line(self, position_1, position_2):
        body = pymunk.Body(body_type=pymunk.Body.STATIC)
        segment = pymunk.Segment(
            body=body,
            a=position_1,
            b=position_2,
            radius=5
        )
        segment.filter = self.unactive_filter
        segment.collision_type = COLLISION_TYPE_TRAIL
        self.env.space.add(body, segment)
        self.create_line_image(segment)
    
    def create_line_image(self, segment):        
        x_a, y_a = segment.a
        x_b, y_b = segment.b
        
        vec_a = pymunk.Vec2d(x_a, y_a)
        vec_b = pymunk.Vec2d(x_b, y_b)
        
        length = vec_a.get_distance(vec_b) + segment.radius
        width = segment.radius*2
        center = (vec_a + vec_b) / 2
        angle = -(degrees(atan2(y_b - y_a, x_b - x_a)) - 90)
        
        image = pygame.transform.scale(self.base_image, (int(width), int(length)))
        image = pygame.transform.rotate(image, angle)
        rect = image.get_rect(center=center)
        
        self.lines.append((segment, image, rect))
    
    def draw(self, surface: pygame.Surface):
        for _, image, rect in self.lines:
            surface.blit(image, rect)