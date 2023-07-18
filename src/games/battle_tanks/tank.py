import math
import pygame
import pymunk

from games.battle_tanks.explosion import Explosion

from .rocket import Rocket

from .settings.constants import FPS, TANK_COLLISION_TYPE, TANK_ROTATE_SPEED, TANK_SPEED, TURRET_BODY_OFFSET, TURRET_ROTATE_SPEED

from typing import TYPE_CHECKING
if TYPE_CHECKING:
    from .env import BattleTanksEnv

class Tank(pygame.sprite.Sprite):
    
    def __init__(self, x, y, color: str, env: 'BattleTanksEnv', mask, enemy_mask, rocket_mask, enemy_rocket_mask):
        super().__init__()
        
        self.env = env
        self.color = color
        
        self.mask = mask
        self.enemy_mask = enemy_mask
        self.rocket_mask = rocket_mask
        self.enemy_rocket_mask = enemy_rocket_mask
        
        self.body_animations = self.create_body_animations(color)
        self.body_animation_index = 0
        self.body_animation_state = "idle"
        self.body_animation_cooldown = 0
        self.body_animation_cooldown_max = FPS // 5
        
        self.body_base_image = self.body_animations[self.body_animation_state][self.body_animation_index]
        self.turret_base_image = self.env.tank_images[color]["turret"]
        self.turret_body_offset = TURRET_BODY_OFFSET
        
        self.main_body = pymunk.Body(body_type=pymunk.Body.DYNAMIC)
        self.main_body.position = (x, y)
        self.main_shape = pymunk.Poly.create_box(
            self.main_body, 
            size=(self.body_base_image.get_width(), self.body_base_image.get_height())
        )
        self.main_shape.density = 1
        self.main_shape.collision_type = TANK_COLLISION_TYPE
        self.main_shape.filter = pymunk.ShapeFilter(
            categories=pymunk.ShapeFilter.ALL_CATEGORIES() ^ rocket_mask, 
            mask=mask
        )
        self.main_shape.sprite = self
        
        self.turret_body = pymunk.Body(body_type=pymunk.Body.KINEMATIC)
        self.turret_body.position = (x, y) + self.turret_body_offset
        self.turret_shape = pymunk.Poly.create_box(self.turret_body, size=(self.turret_base_image.get_width(), self.turret_base_image.get_height()))
        self.turret_shape.density = 1
        self.turret_shape.filter = pymunk.ShapeFilter(categories=0)
        self.turret_height = self.turret_base_image.get_height()
        
        self.env.space.add(self.main_body, self.main_shape)
        self.env.space.add(self.turret_body, self.turret_shape)
        
        self.forward = False
        self.backward = False
        self.right = False
        self.left = False
        self.turret_right = False
        self.turret_left = False
        self.fire = False
        
        self.speed = TANK_SPEED
        self.rotate_speed = TANK_ROTATE_SPEED
        self.turret_rotate_speed = TURRET_ROTATE_SPEED
        
        self.fire_rate = 2
        self.fire_cooldown_max = 60 / self.fire_rate
        self.fire_cooldown = 0
        
        self.hp = 100
        self.is_death = False
    
    def create_compound_image(self, body_image: pygame.Surface, track_image: pygame.Surface):
        compound_image = pygame.Surface((body_image.get_width(), body_image.get_height()), pygame.SRCALPHA)
        compound_image.blit(track_image, (0, 0))
        compound_image.blit(body_image, (0, 0))
        return compound_image
    
    def create_body_animations(self, color: str):
        images = []
        body_image = self.env.tank_images[color]["body"]
        for i in range(len(self.env.tank_images["tracks"])):
            track_image = self.env.tank_images["tracks"][i]
            body_base_image = self.create_compound_image(track_image=track_image, body_image=body_image)
            images.append(body_base_image)
        
        idle = images[:1]
        move_forward = images[:]
        move_backward = images[:]
        move_backward.reverse()
        
        return {
            "idle": idle,
            "move_forward": move_forward,
            "move_backward": move_backward
        }
    
    def update(self):
        self.move()
        self.update_turret_position()
        self.shoot()

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
    
    def update_turret_position(self):
        offset = self.turret_body_offset.rotated(self.main_body.angle)
        position = self.main_body.position + offset
        self.turret_body.position = position
    
    def shoot(self):
        if self.fire_cooldown > 0:
            self.fire_cooldown -= 1
        
        if self.fire and self.fire_cooldown == 0:
            correct_angle = self.turret_body.angle - math.radians(90)
            x = self.turret_body.position.x + math.cos(correct_angle)*self.turret_height/1.75
            y = self.turret_body.position.y + math.sin(correct_angle)*self.turret_height/1.75
            Rocket(x, y, self.turret_body.angle, self)
            self.fire_cooldown = self.fire_cooldown_max
    
    def take_damage(self, damage):
        self.hp -= damage
        if self.hp <= 0:
            self.hp = 0
            self.is_death = True
            self.explode()
    
    def explode(self):
        self.kill()
        self.env.space.remove(self.main_body, self.main_shape, self.turret_body, self.turret_shape)
        if self.env.render_mode == "human":
            Explosion(self.main_body.position.x, self.main_body.position.y, "tank", self.env)
    
    def update_render(self):
        if self.forward and not self.backward:
            self.update_animation_state("move_forward")
        elif self.backward and not self.forward:
            self.update_animation_state("move_backward")
        else:
            self.update_animation_state("idle")
            
        self.update_animation()
        self.update_images()
    
    def update_animation_state(self, state: str):
        if self.body_animation_state != state:
            self.body_animation_state = state
            self.body_animation_index = 0
            self.body_animation_cooldown = self.body_animation_cooldown_max
    
    def update_animation(self):
        if self.body_animation_cooldown > 0:
            self.body_animation_cooldown -= 1
        
        if self.body_animation_cooldown == 0:
            self.body_animation_index = (self.body_animation_index + 1) % len(self.body_animations[self.body_animation_state])
            self.body_base_image = self.body_animations[self.body_animation_state][self.body_animation_index]
            self.body_animation_cooldown = self.body_animation_cooldown_max
    
    def update_images(self):
        self.main_image = pygame.transform.rotate(self.body_base_image, -math.degrees(self.main_body.angle))
        self.turret_image = pygame.transform.rotate(self.turret_base_image, -math.degrees(self.turret_body.angle))
        self.main_rect = self.main_image.get_rect(center=self.main_body.position)
        self.turret_rect = self.turret_image.get_rect(center=self.turret_body.position)
    
    def draw(self, surface: pygame.Surface):
        surface.blit(self.main_image, self.main_rect)
        surface.blit(self.turret_image, self.turret_rect)