import random
import pygame
import pymunk
from pymunk import pygame_util

import itertools
from math import pi, radians, sin, cos
import numpy as np

import gymnasium as gym
from stable_baselines3.common.base_class import BaseAlgorithm

from .tile import Tile
from .tank import Tank

from .settings.constants import (
    FPS, FRAME_SKIP, MAX_TIMESTEPS, ROCKET_EXPLOSION_INFO, MAP_HEIGHT, MAP_SCALE, MAP_WIDTH, ROCKET_BLUE_MASK, 
    ROCKET_COLLISION_TYPE, ROCKET_RED_MASK, ROCKET_SCALE, 
    SCALED_TILE_SIZE, TANK_1_ANGLE, TANK_1_POSITION, TANK_2_ANGLE, TANK_2_POSITION, TANK_BLUE_MASK, TANK_COLLISION_TYPE, TANK_EXPLOSION_INFO, 
    TANK_RED_MASK, TANK_SCALE, TILE_COLLISION_TYPE, TILE_MASK
)

from games.util.util import conditional_convert_alpha, load_csv, load_images_from_sheet, scale_image

"""
    Reward Function:
    - 1.000 * End Reward      (-1 | 0 | 1)
    - 0.005 * Timestep Reward (0 -> -1)
    - 0.100   * Damage Reward (-1 | 0 | 1)
"""

END_REWARD_WEIGHT      = 1
TIMESTEP_REWARD_WEIGHT = 0.005
DAMAGE_REWARD_WEIGHT   = 0.1

class BattleTanksEnv(gym.Env):
    
    metadata = {'render_modes': ['human'], 'render_fps': FPS, 'player2_modes': ['random', 'agent', 'human']}
    
    def __init__(
        self, render_mode=None, player2_mode=None, 
        player2_agent: None|BaseAlgorithm=None, player2_agent_choice: None|list[BaseAlgorithm]=None,
        render_in_step=False
    ):
        pygame.init()
        
        self.width      = MAP_WIDTH
        self.height     = MAP_HEIGHT
        self.fps        = FPS
        self.frame_skip = FRAME_SKIP
        self.max_steps  = MAX_TIMESTEPS
        
        self.render_in_step = render_in_step
        self.render_mode    = render_mode
        
        self.rays          = 32
        self.ray_length    = self.width
        self.ray_angle     = radians(360 / self.rays)
        self.ray_types     = 4 # tile, enemy tank, enemy rocket, rocket
        self.ray_positions = 2 # body, turret
        
        self.extra_observations = 3 # angle sin, angle cos, angle norm
        
        # TODO: Test observation space
        self.observation_space = gym.spaces.Box(
            low=0, 
            high=1, 
            shape=(
                self.ray_types*self.rays*self.ray_positions + self.extra_observations, 
            ), 
            dtype=np.float64
        )
        self.action_space = gym.spaces.Discrete(8)
        self.human_action = 69
        
        self.player2_mode = player2_mode
        self.player2_agent = player2_agent
        if player2_agent_choice is not None:
            self.player2_agent = random.choice(player2_agent_choice)
        print(f"Player 2 Agent: {self.player2_agent}")
        
        self.screen = None
        self.draw_util = None
        self.clock = None
        
        render_human = (render_mode == 'human')
        if render_human:
            self.setup_human_render()
        self.load_images(convert_alpha=render_human)
    
    def setup_human_render(self):
        self.screen = pygame.display.set_mode((self.width, self.height))
        self.draw_util = pygame_util.DrawOptions(self.screen)
        self.clock = pygame.time.Clock()
    
    def load_images(self, convert_alpha: bool = False):
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
        
        self.explosions_images = {}
        
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

        for (type, scale, length) in [ROCKET_EXPLOSION_INFO, TANK_EXPLOSION_INFO]:
            explosion_sheet = conditional_convert_alpha(
                scale_image(pygame.image.load(f"assets/battle_tanks/images/explosions/{type}_explosion.png"), scale),
                convert_alpha
            )
            explosion_images = load_images_from_sheet(explosion_sheet, explosion_sheet.get_width()//length, explosion_sheet.get_height())
            self.explosions_images[type] = explosion_images

        tileset_sheet = conditional_convert_alpha(
            scale_image(pygame.image.load("assets/battle_tanks/images/tilesets/jawbreaker.png"), MAP_SCALE),
            convert_alpha
        )
        self.tileset = load_images_from_sheet(tileset_sheet, SCALED_TILE_SIZE, SCALED_TILE_SIZE)
    
    def step(self, action):
        if self.terminated:
            return self.observation_space.sample(), 0, True, False, {}
        
        self.perform_player1_action(action)
        self.perform_player2_action()
        
        tank_1_pre_hp = self.tank_1.hp
        tank_2_pre_hp = self.tank_2.hp
        
        self.space.step(1/self.fps)
        self.tanks.update()
        self.rockets.update()
        
        is_human_action = (action == self.human_action)
        reward      = self.calculate_reward(tank_1_pre_hp, tank_2_pre_hp) if not is_human_action else 0
        observation = self.get_observation(self.tank_1) if not is_human_action else self.observation_space.sample()
        
        if self.tank_1.is_death or self.tank_2.is_death:
            self.terminated = True
        
        self.steps_taken += 1
        
        if self.render_in_step:
            self.render()
        
        return observation, reward, self.terminated, False, {}
    
    def perform_player1_action(self, action):
        if action == self.human_action:
            self.human_input_player1()
            return
        
        self.perform_action(action, self.tank_1)
    
    def perform_player2_action(self):
        mode = self.player2_mode
        
        if mode == 'human':
            self.human_input_player2()
            return

        if self.frames_to_skip > 0:
            self.frames_to_skip -= 1
            self.perform_action(self.last_player2_action, self.tank_2)
            return

        if mode == 'random':
            action = self.action_space.sample()
        elif mode == 'agent':
            if self.player2_agent is not None:
                action, _ = self.player2_agent.predict(self.get_observation(self.tank_2))
            else:
                action = None
        
        self.last_player2_action = action
        self.frames_to_skip      = self.frame_skip
        self.perform_action(action, self.tank_2)
    
    def perform_action(self, action, tank: Tank):
        tank.forward      = (action == 0)
        tank.backward     = (action == 1)
        tank.right        = (action == 2)
        tank.left         = (action == 3)
        tank.turret_right = (action == 4)
        tank.turret_left  = (action == 5)
        tank.fire         = (action == 6)
    
    def human_input_player1(self):
        keys = pygame.key.get_pressed()
        self.tank_1.forward      = keys[pygame.K_w]
        self.tank_1.backward     = keys[pygame.K_s]
        self.tank_1.right        = keys[pygame.K_d]
        self.tank_1.left         = keys[pygame.K_a]
        self.tank_1.turret_right = keys[pygame.K_RIGHT]
        self.tank_1.turret_left  = keys[pygame.K_LEFT]
        self.tank_1.fire         = keys[pygame.K_SPACE]
    
    # Currently same input as player1
    def human_input_player2(self):
        keys = pygame.key.get_pressed()
        self.tank_2.forward      = keys[pygame.K_w]
        self.tank_2.backward     = keys[pygame.K_s]
        self.tank_2.right        = keys[pygame.K_d]
        self.tank_2.left         = keys[pygame.K_a]
        self.tank_2.turret_right = keys[pygame.K_RIGHT]
        self.tank_2.turret_left  = keys[pygame.K_LEFT]
        self.tank_2.fire         = keys[pygame.K_SPACE]
    
    def calculate_reward(self, tank_1_pre_hp: int, tank_2_pre_hp: int):
        reward = 0 

        # End Reward
        if self.tank_1.is_death:
            reward -= END_REWARD_WEIGHT
        if self.tank_2.is_death:
            reward += END_REWARD_WEIGHT
        
        # Timestep Reward
        timestep_reward = self.steps_taken / self.max_steps
        reward -= TIMESTEP_REWARD_WEIGHT * timestep_reward
        
        # Damage Reward
        if tank_1_pre_hp > self.tank_1.hp:
            reward -= DAMAGE_REWARD_WEIGHT
        if tank_2_pre_hp > self.tank_2.hp:
            reward += DAMAGE_REWARD_WEIGHT
        
        return reward
    
    def get_observation(self, tank: Tank):
        start = tank.main_body.position
        start_angle = tank.main_body.angle
        turret_start = tank.turret_body.position
        turret_start_angle = tank.turret_body.angle
        
        # Filters
        tile_filter         = pymunk.ShapeFilter(categories=TILE_MASK)
        enemy_filter        = pymunk.ShapeFilter(categories=tank.enemy_mask)
        rocket_filter       = pymunk.ShapeFilter(categories=tank.rocket_mask)
        enemy_rocket_filter = pymunk.ShapeFilter(categories=tank.enemy_rocket_mask)
        
        # Body raycasts
        tile_ray = self.raycast(
            start=start,
            amount=self.rays,
            length=self.ray_length,
            start_angle=start_angle,
            filter=tile_filter
        )
        enemy_ray = self.raycast(
            start=start,
            amount=self.rays,
            length=self.ray_length,
            start_angle=start_angle,
            filter=enemy_filter
        )
        rocket_ray = self.raycast(
            start=start,
            amount=self.rays,
            length=self.ray_length,
            start_angle=start_angle,
            filter=rocket_filter
        )
        enemy_rocket_ray = self.raycast(
            start=start,
            amount=self.rays,
            length=self.ray_length,
            start_angle=start_angle,
            filter=enemy_rocket_filter
        )
        
        # Turret raycasts
        turret_tile_ray = self.raycast(
            start=turret_start,
            amount=self.rays,
            length=self.ray_length,
            start_angle=turret_start_angle,
            filter=tile_filter
        )
        turret_enemy_ray = self.raycast(
            start=turret_start,
            amount=self.rays,
            length=self.ray_length,
            start_angle=turret_start_angle,
            filter=enemy_filter
        )
        turret_rocket_ray = self.raycast(
            start=turret_start,
            amount=self.rays,
            length=self.ray_length,
            start_angle=turret_start_angle,
            filter=rocket_filter
        )
        turret_enemy_rocket_ray = self.raycast(
            start=turret_start,
            amount=self.rays,
            length=self.ray_length,
            start_angle=turret_start_angle,
            filter=enemy_rocket_filter
        )
        
        # Extra observations
        angle_difference = tank.turret_body.angle - tank.main_body.angle
        angle_difference_sin = sin(angle_difference)
        angle_difference_cos = cos(angle_difference)
        angle_difference_norm = angle_difference / 2 * pi
        
        obs = list(itertools.chain(
            tile_ray, enemy_ray, rocket_ray, enemy_rocket_ray,
            turret_tile_ray, turret_enemy_ray, turret_rocket_ray, turret_enemy_rocket_ray,
            [angle_difference_sin, angle_difference_cos, angle_difference_norm]
        ))
        return np.array(obs, dtype=np.float64)
    
    def raycast(self, start, amount, length, start_angle, filter):
        results = []
        
        for i in range(amount):
            angle = i * self.ray_angle + start_angle
            a = start
            b = (start[0] + length * cos(angle), start[1] + length * sin(angle))
            result = self.space.segment_query_first(a, b, 1, filter)
            result = 1 - result.alpha if result is not None else 0
            results.append(result)
        
        return results
    
    def reset(self, seed=None, options=None):
        self.space      = pymunk.Space()
        self.ground     = pygame.sprite.Group()
        self.walls      = pygame.sprite.Group()
        self.tanks      = pygame.sprite.Group()
        self.rockets    = pygame.sprite.Group()
        self.explosions = pygame.sprite.Group()
        self.load_map("base")
        self.setup_tanks()
        self.setup_collision_handlers()
        self.frames_to_skip      = 0
        self.steps_taken         = 0
        self.last_player2_action = None
        self.terminated          = False
        observation              = self.get_observation(self.tank_1)
        return observation, {}
    
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
    
    def setup_tanks(self):
        x_1, y_1 = TANK_1_POSITION
        x_2, y_2 = TANK_2_POSITION
        self.tank_1 = Tank(x_1, y_1, "blue", self, TANK_BLUE_MASK, TANK_RED_MASK, ROCKET_BLUE_MASK, ROCKET_RED_MASK)
        self.tank_2 = Tank(x_2, y_2, "red", self, TANK_RED_MASK, TANK_BLUE_MASK, ROCKET_RED_MASK, ROCKET_BLUE_MASK)
        self.tank_1.main_body.angle   = TANK_1_ANGLE
        self.tank_1.turret_body.angle = TANK_1_ANGLE
        self.tank_2.main_body.angle   = TANK_2_ANGLE
        self.tank_2.turret_body.angle = TANK_2_ANGLE
        self.tanks.add(self.tank_1, self.tank_2)
    
    def setup_collision_handlers(self):
        tank_stop_handler = self.space.add_collision_handler(TANK_COLLISION_TYPE, TILE_COLLISION_TYPE)
        rocket_explode_handler = self.space.add_wildcard_collision_handler(ROCKET_COLLISION_TYPE)
        
        def stop_tank(arbiter, space, data):
            point_set = arbiter.contact_point_set
            arbiter.shapes[0].body.position += point_set.normal * point_set.points[0].distance
        
        def explode_rocket(arbiter, space, data):
            rocket = arbiter.shapes[0].sprite
            target = arbiter.shapes[1]
            
            if target.collision_type == TANK_COLLISION_TYPE:
                target.sprite.take_damage(rocket.damage)
            
            rocket.explode()
            return False
        
        tank_stop_handler.post_solve = stop_tank
        rocket_explode_handler.begin = explode_rocket
    
    def render(self):
        if self.render_mode == 'human':
            self.render_human()
    
    def render_human(self):
        self.ground.draw(self.screen)
        # self.space.debug_draw(self.draw_util)
        self.walls.draw(self.screen)
        for tank in self.tanks:
            tank.update_render()
            tank.draw(self.screen)
        for rocket in self.rockets:
            rocket.update_render()
            rocket.draw(self.screen)
        for explosion in self.explosions:
            explosion.update_render()
            explosion.draw(self.screen)
        pygame.display.flip()
        self.clock.tick(self.fps)
    
    def close(self):
        pygame.quit()