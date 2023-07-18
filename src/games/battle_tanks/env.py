import pygame
import pymunk
from pymunk import pygame_util

from .tile import Tile
from .tank import Tank

from .settings.constants import MAP_HEIGHT, MAP_SCALE, MAP_WIDTH, ROCKET_COLLISION_TYPE, ROCKET_SCALE, SCALED_TILE_SIZE, TANK_COLLISION_TYPE, TANK_SCALE, TILE_COLLISION_TYPE

from games.util.util import conditional_convert_alpha, load_csv, load_images_from_sheet, scale_image

class BattleTanksEnv:
    
    def __init__(self):
        pygame.init()
        
        self.screen = pygame.display.set_mode((MAP_WIDTH, MAP_HEIGHT))
        self.clock = pygame.time.Clock()
        self.fps = 60
        
        self.space = pymunk.Space()
        self.draw_util = pygame_util.DrawOptions(self.screen)
        
        self.ground = pygame.sprite.Group()
        self.walls = pygame.sprite.Group()
        self.tanks = pygame.sprite.Group()
        self.rockets = pygame.sprite.Group()
        self.load_images()
        self.load_map("base")
        self.setup_collision_handlers()
        self.tank_1 = Tank(400, 300, "blue", self)
        self.tank_2 = Tank(500, 300, "red", self)
        self.tanks.add(self.tank_1, self.tank_2)
    
    def input(self):
        keys = pygame.key.get_pressed()
        self.tank_1.forward = keys[pygame.K_w]
        self.tank_1.backward = keys[pygame.K_s]
        self.tank_1.right = keys[pygame.K_d]
        self.tank_1.left = keys[pygame.K_a]
        self.tank_1.turret_right = keys[pygame.K_RIGHT]
        self.tank_1.turret_left = keys[pygame.K_LEFT]
        self.tank_1.fire = keys[pygame.K_SPACE]
    
    def step(self):
        self.space.step(1/self.fps)
        self.tanks.update()
        self.rockets.update()
    
    def reset(self):
        pass
    
    def render(self):
        self.screen.fill((255, 255, 255))
        self.ground.draw(self.screen)
        # self.space.debug_draw(self.draw_util)
        self.walls.draw(self.screen)
        for tank in self.tanks:
            tank.update_render()
            tank.draw(self.screen)
        for rocket in self.rockets:
            rocket.update_render()
            rocket.draw(self.screen)
        pygame.display.flip()
        self.clock.tick(self.fps)
    
    def close(self):
        pygame.quit()
    
    def setup_collision_handlers(self):
        tank_stop_handler = self.space.add_collision_handler(TANK_COLLISION_TYPE, TILE_COLLISION_TYPE)
        rocket_explode_handler = self.space.add_wildcard_collision_handler(ROCKET_COLLISION_TYPE)
        
        def stop_tank(arbiter, space, data):
            point_set = arbiter.contact_point_set
            arbiter.shapes[0].body.position += point_set.normal * point_set.points[0].distance
        
        def explode_rocket(arbiter, space, data):
            rocket = arbiter.shapes[0].sprite
            rocket.kill()
            self.space.remove(rocket.body, rocket.shape)
            return False
        
        tank_stop_handler.post_solve = stop_tank
        rocket_explode_handler.begin = explode_rocket
    
    def load_images(self, convert_alpha: bool = True):
        
        self.rocket_images = {}
        
        self.tank_images = {
            "blue": {
                "body": None,
                "turret": None,
            },
            "red": {
                "body": None,
                "turret": None,
            },
            "tracks": []
        }
        
        
        for color in ["red", "blue"]:
            rocket_image = conditional_convert_alpha(
                scale_image(pygame.image.load(f"assets/battle_tanks/images/rockets/rocket_{color}.png"), TANK_SCALE*ROCKET_SCALE),
                convert_alpha
            )
            self.rocket_images[color] = rocket_image
        
            body_image = conditional_convert_alpha(
                scale_image(pygame.image.load(f"assets/battle_tanks/images/tanks/{color}_body.png"), TANK_SCALE),
                convert_alpha
            )
            turret_image = conditional_convert_alpha(
                scale_image(pygame.image.load(f"assets/battle_tanks/images/tanks/{color}_gun_with_offset.png"), TANK_SCALE),
                convert_alpha
            )
            self.tank_images[color]["body"] = body_image
            self.tank_images[color]["turret"] = turret_image
            
        for i in ['a', 'b']:
            track_image = conditional_convert_alpha(
                scale_image(pygame.image.load(f"assets/battle_tanks/images/tanks/track_{i}.png"), TANK_SCALE),
                convert_alpha
            )
            self.tank_images["tracks"].append(track_image)

        tileset_sheet = conditional_convert_alpha(
            scale_image(pygame.image.load("assets/battle_tanks/images/tilesets/jawbreaker.png"), MAP_SCALE),
            convert_alpha
        )
        self.tileset = load_images_from_sheet(tileset_sheet, SCALED_TILE_SIZE, SCALED_TILE_SIZE)
    
    def load_map(self, map_name: str):
        ground_csv = load_csv(f"assets/battle_tanks/maps/{map_name}/{map_name}_ground.csv")
        wall_csv = load_csv(f"assets/battle_tanks/maps/{map_name}/{map_name}_walls.csv")
        
        for y, row in enumerate(ground_csv):
            for x, tile in enumerate(row):
                if tile != "-1":
                    tile = Tile(x * SCALED_TILE_SIZE, y * SCALED_TILE_SIZE, self.tileset[int(tile)], False, self)
                    self.ground.add(tile)
        
        for y, row in enumerate(wall_csv):
            for x, tile in enumerate(row):
                if tile != "-1":
                    tile = Tile(x * SCALED_TILE_SIZE, y * SCALED_TILE_SIZE, self.tileset[int(tile)], True, self)
                    self.walls.add(tile)