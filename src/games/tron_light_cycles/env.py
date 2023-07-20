import random
import pygame
import pymunk
from pymunk import pygame_util

import itertools
from math import radians, cos, sin
import numpy as np

import gymnasium as gym
from stable_baselines3.common.base_class import BaseAlgorithm

from games.util.util import conditional_convert_alpha, scale_image
from .settings.constants import (
    COLLISION_TYPE_CYCLE, CYCLE_1_ANGLE, CYCLE_1_POSITION,
    CYCLE_2_ANGLE, CYCLE_2_POSITION, CYCLE_SCALE, FPS, FRAME_SKIP, 
    MAP_HEIGHT, MAP_WIDTH, MASK_CYCLE_BLUE, MASK_CYCLE_RED, MASK_TRAIL, 
    MASK_WALL, MAX_TIMESTEPS
)

from .wall import Wall
from .cycle import Cycle

"""
    Reward Function:
    - 1.000 * End Reward (-1 | 0 | 1)
    - 0.005 * Timestep Reward (0 -> 1)
"""

END_REWARD_WEIGHT      = 1
TIMESTEP_REWARD_WEIGHT = 0.005

class TronLightCyclesEnv(gym.Env):
    
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

        self.rays       = 64
        self.ray_length = self.width
        self.ray_angle  = radians(360 / self.rays)
        self.ray_types  = 3 # wall, enemy cycle, trail
        
        self.observation_space = gym.spaces.Box(low=0, high=1, shape=(self.ray_types*self.rays, ), dtype=np.float64)
        self.action_space      = gym.spaces.Discrete(3) # 0: left, 1: right, 2: none
        self.human_action      = 69
        
        self.player2_mode  = player2_mode
        self.player2_agent = player2_agent
        if player2_agent_choice is not None:
            self.player2_agent = random.choice(player2_agent_choice)
        print(f"Player 2 Agent: {self.player2_agent}")
        
        self.screen    = None
        self.draw_util = None
        self.clock     = None
        
        render_human = (render_mode == 'human')
        if render_human:
            self.setup_human_render()
        self.load_images(convert_alpha=render_human)
    
    def setup_human_render(self):
        self.screen = pygame.display.set_mode((self.width, self.height))
        self.draw_util = pygame_util.DrawOptions(self.screen)
        self.clock = pygame.time.Clock()
    
    def load_images(self, convert_alpha=False):
        self.cycle_images = {}
        self.trail_images = {}
        
        for color in ['red', 'blue']:
            cycle_image = conditional_convert_alpha(
                scale_image(
                    pygame.image.load(f"assets/tron_light_cycles/images/tron_cycle_{color}.png"),
                    CYCLE_SCALE
                ),
                convert_alpha
            )
            self.cycle_images[color] = cycle_image
            
            trail_image = conditional_convert_alpha(
                scale_image(
                    pygame.image.load(f"assets/tron_light_cycles/images/tron_trail_{color}.png"),
                    1
                ),
                convert_alpha
            )
            self.trail_images[color] = trail_image
    
    def step(self, action):
        if self.terminated:
            return None, None, True, False, {}
                
        self.perform_player1_action(action)
        self.perform_player2_action()
        
        self.space.step(1/self.fps)
        self.cycles.update()
        
        is_human_action = (action == self.human_action)
        reward = self.calculate_reward() if not is_human_action else None
        observation = self.get_observation(self.cycle_1) if not is_human_action else None
        
        if self.cycle_1.is_death or self.cycle_2.is_death:
            self.terminated = True
        
        self.steps_taken += 1
        
        return observation, reward, self.terminated, False, {}
    
    def perform_player1_action(self, action):
        if action == self.human_action:
            self.human_input_player1()
            return
        
        self.perform_action(action, self.cycle_1)
    
    def perform_player2_action(self):
        mode = self.player2_mode
        
        if mode == 'human':
            self.human_input_player2()
            return
        
        if self.frames_to_skip > 0:
            self.frames_to_skip -= 1
            self.perform_action(self.last_player2_action, self.cycle_2)
            return

        if mode == 'random':
            action = self.action_space.sample()
        elif mode == 'agent':
            if self.player2_agent is not None:
                action, _ = self.player2_agent.predict(self.get_observation(self.cycle_2))
            else:
                action = None
        
        self.last_player2_action = action
        self.frames_to_skip = self.frame_skip
        self.perform_action(action, self.cycle_2)
    
    def perform_action(self, action, cycle: Cycle):
        # 0: left, 1: right, 2: none
        cycle.left  = (action == 0)
        cycle.right = (action == 1)
    
    def human_input_player1(self):
        keys = pygame.key.get_pressed()
        self.cycle_1.left  = keys[pygame.K_a]
        self.cycle_1.right = keys[pygame.K_d]
    
    def human_input_player2(self):
        keys = pygame.key.get_pressed()
        self.cycle_2.left  = keys[pygame.K_LEFT]
        self.cycle_2.right = keys[pygame.K_RIGHT]
    
    def calculate_reward(self):
        reward = 0 

        # End Reward
        if self.cycle_1.is_death:
            reward -= END_REWARD_WEIGHT
        if self.cycle_2.is_death:
            reward += END_REWARD_WEIGHT
        
        # Timestep Reward
        timestep_reward = self.steps_taken / self.max_steps
        reward += TIMESTEP_REWARD_WEIGHT * timestep_reward
        
        return reward
    
    def get_observation(self, cycle: Cycle):
        start = cycle.body.position
        start_angle = cycle.body.angle
        
        # Filters
        wall_filter  = pymunk.ShapeFilter(categories=MASK_WALL)
        trail_filter = pymunk.ShapeFilter(categories=MASK_TRAIL)
        enemy_filter = pymunk.ShapeFilter(categories=cycle.enemy_mask)
        
        # Raycast
        wall_ray  = self.raycast(
            start=start,
            amount=self.rays,
            length=self.ray_length,
            start_angle=start_angle,
            filter=wall_filter
        )
        trail_ray = self.raycast(
            start=start, 
            amount=self.rays,
            length=self.ray_length,
            start_angle=start_angle,
            filter=trail_filter
        )
        enemy_ray = self.raycast(
            start=start, 
            amount=self.rays,
            length=self.ray_length,
            start_angle=start_angle,
            filter=enemy_filter
        )
        
        obs = list(itertools.chain(wall_ray, trail_ray, enemy_ray))
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
        self.space = pymunk.Space()
        self.cycles = pygame.sprite.Group()
        self.trails = pygame.sprite.Group()
        self.setup_walls()
        self.setup_cycles()
        self.setup_collision_handlers()
        self.frames_to_skip = 0 # for second player
        self.last_player2_action = None
        self.steps_taken = 0
        self.terminated = False
        observation = self.get_observation(self.cycle_1)
        return observation, {}
    
    def setup_walls(self):
        Wall((0, -1), (self.width, 0), self)
        Wall((-1, 0), (0, self.height), self)
        Wall((self.width, 0), (self.width, self.height), self)
        Wall((0, self.height), (self.width, self.height), self)
    
    def setup_cycles(self):
        x_1, y_1 = CYCLE_1_POSITION
        x_2, y_2 = CYCLE_2_POSITION
        self.cycle_1 = Cycle(x=x_1, y=y_1, color="blue", env=self, mask=MASK_CYCLE_BLUE, enemy_mask=MASK_CYCLE_RED)
        self.cycle_2 = Cycle(x=x_2, y=y_2, color="red", env=self, mask=MASK_CYCLE_RED, enemy_mask=MASK_CYCLE_BLUE)
        self.cycle_1.body.angle = CYCLE_1_ANGLE
        self.cycle_2.body.angle = CYCLE_2_ANGLE
        self.cycles.add(self.cycle_1, self.cycle_2)
    
    def setup_collision_handlers(self):
        cycle_hit = self.space.add_wildcard_collision_handler(COLLISION_TYPE_CYCLE)
        
        def cycle_hit_begin(arbiter, space, data):
            cycle = arbiter.shapes[0].sprite
            cycle.die()
            return False
        
        cycle_hit.begin = cycle_hit_begin
    
    def render(self):
        if self.render_mode == 'human':
            self.render_human()
    
    def render_human(self):
        self.screen.fill((33, 33, 33))
        self.space.debug_draw(self.draw_util)
        for trail in self.trails:
            trail.draw(self.screen)
        for cycle in self.cycles:
            cycle.update_render()
            cycle.draw(self.screen)
        pygame.display.flip()
        self.clock.tick(self.fps)
    
    def close(self):
        pygame.quit()
