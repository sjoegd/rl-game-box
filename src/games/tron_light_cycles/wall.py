import pymunk

from typing import TYPE_CHECKING

from games.tron_light_cycles.settings.constants import COLLISION_TYPE_WALL, MASK_WALL
if TYPE_CHECKING:
    from .env import TronLightCyclesEnv

class Wall:
    
    def __init__(self, start, end, env: 'TronLightCyclesEnv'):
        self.env = env
        self.body = pymunk.Body(body_type=pymunk.Body.STATIC)
        self.shape = pymunk.Segment(
            body=self.body,
            a=start,
            b=end,
            radius=1
        )
        self.shape.collision_type = COLLISION_TYPE_WALL
        self.shape.filter = pymunk.ShapeFilter(mask=MASK_WALL)
        self.env.space.add(self.body, self.shape)