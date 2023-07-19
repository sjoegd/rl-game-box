import pygame
import pymunk
from pymunk import pygame_util
from games.tron_light_cycles.settings.constants import COLLISION_TYPE_CYCLE, COLLISION_TYPE_TRAIL, CYCLE_SCALE

from games.util.util import scale_image

from .cycle import Cycle

class TronLightCyclesEnv:
    
    def __init__(self):
        pygame.init()
        self.screen = pygame.display.set_mode((1280, 720))
        self.draw_util = pygame_util.DrawOptions(self.screen)
        self.clock = pygame.time.Clock()
        self.fps = 60
        self.space = pymunk.Space()
        self.cycles = pygame.sprite.Group()
        self.trails = pygame.sprite.Group()
        self.load_images()
        self.setup_collision_handlers()
        self.cycle_1 = Cycle(640, 360, "blue", self)
        self.cycle_2 = Cycle(800, 360, "red", self)
        self.cycles.add(self.cycle_1, self.cycle_2)
    
    def load_images(self):
        self.cycle_images = {}
        self.trail_images = {}
        
        for color in ['red', 'blue']:
            cycle_image = scale_image(
                pygame.image.load(f"assets/tron_light_cycles/images/tron_cycle_{color}.png").convert_alpha(),
                CYCLE_SCALE
            )
            self.cycle_images[color] = cycle_image
            
            trail_image = scale_image(
                pygame.image.load(f"assets/tron_light_cycles/images/tron_trail_{color}.png").convert_alpha(),
                1
            )
            self.trail_images[color] = trail_image
    
    def setup_collision_handlers(self):
        cycle_hit_line = self.space.add_collision_handler(COLLISION_TYPE_CYCLE, COLLISION_TYPE_TRAIL)
        
        def cycle_hit_line_begin(arbiter, space, data):
            print("Cycle hit line")
            return False
        
        cycle_hit_line.begin = cycle_hit_line_begin
    
    def input(self):
        keys = pygame.key.get_pressed()
        self.cycle_1.forward = keys[pygame.K_w]
        self.cycle_1.right = keys[pygame.K_d]
        self.cycle_1.left = keys[pygame.K_a]
        
        self.cycle_2.forward = keys[pygame.K_UP]
        self.cycle_2.right = keys[pygame.K_RIGHT]
        self.cycle_2.left = keys[pygame.K_LEFT]
    
    def step(self):
        self.cycles.update()
        self.space.step(1/self.fps)
    
    def reset(self):
        pass
    
    def render(self):
        self.screen.fill((33, 33, 33))
        for trail in self.trails:
            trail.draw(self.screen)
        for cycle in self.cycles:
            cycle.update_render()
            cycle.draw(self.screen)
        # self.space.debug_draw(self.draw_util)
        pygame.display.flip()
        self.clock.tick(self.fps)
    
    def close(self):
        pass
