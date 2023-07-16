import math
import pygame


class Tank(pygame.sprite.Sprite):
    def __init__(self, x, y, body_image, turret_image):
        super().__init__()
        self.body_base_image = body_image
        self.body_image = body_image
        self.turret_base_image = turret_image
        self.turret_image = turret_image
        self.body_rect = self.body_base_image.get_rect(center=(x, y))
        self.turret_rect = self.turret_base_image.get_rect(center=self.body_rect.center)
        self.turret_body_offset = (0, 25)
        self.body_angle = 0
        self.turret_angle = 0
        
        self.forward = False
        self.backward = False
        self.right = False
        self.left = False
        
        self.speed = 5
        self.rotate_speed = 5        
    
    def update(self):
        
        angle = self.body_angle + 90
        
        if self.forward:
            self.body_rect.x += self.speed * math.cos(math.radians(-angle))
            self.body_rect.y += self.speed * math.sin(math.radians(-angle))
            
        if self.backward:
            self.body_rect.x -= self.speed * math.cos(math.radians(-angle))
            self.body_rect.y -= self.speed * math.sin(math.radians(-angle))
        
        if self.right:
            self.body_angle -= self.rotate_speed
        
        if self.left:
            self.body_angle += self.rotate_speed
            
        self.body_image = pygame.transform.rotate(self.body_base_image, self.body_angle)
        self.body_rect = self.body_image.get_rect(center=self.body_rect.center)
        
        rotated_offset = pygame.math.Vector2(self.turret_body_offset).rotate(-self.body_angle)
        turret_center = (self.body_rect.centerx + rotated_offset.x, self.body_rect.centery + rotated_offset.y)
        
        mouse_pos = pygame.mouse.get_pos()
        
        new_turret_angle = math.degrees(math.atan2(mouse_pos[1] - turret_center[1], mouse_pos[0] - turret_center[0])) + 90
        self.turret_angle = new_turret_angle
        
        self.turret_image = pygame.transform.rotate(self.turret_base_image, -self.turret_angle)
        self.turret_rect = self.turret_image.get_rect(center=turret_center)
    
    def draw(self, surface):
        surface.blit(self.body_image, self.body_rect)
        surface.blit(self.turret_image, self.turret_rect)