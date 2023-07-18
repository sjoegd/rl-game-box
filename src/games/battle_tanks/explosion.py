
import pygame

from typing import TYPE_CHECKING

from games.battle_tanks.settings.constants import FPS
if TYPE_CHECKING:
    from .env import BattleTanksEnv

class Explosion(pygame.sprite.Sprite):
    
    def __init__(self, x, y, type: str, env: 'BattleTanksEnv'):
        
        super().__init__()
        
        self.env = env
        
        self.images = env.explosions_images[type]
        self.image_index = 0
        self.image_cooldown_max = FPS // 8
        self.image_cooldown = 0
        
        self.image = self.images[self.image_index]
        self.rect = self.image.get_rect(center=(x, y))
        
        self.env.explosions.add(self)
    
    def update_render(self):
        if self.image_cooldown > 0:
            self.image_cooldown -= 1
        
        if self.image_cooldown == 0:
            self.image_index += 1
            if self.image_index >= len(self.images):
                self.kill()
            else:
                self.image = self.images[self.image_index]
                self.rect = self.image.get_rect(center=self.rect.center)
                self.image_cooldown = self.image_cooldown_max
    
    def draw(self, surface: pygame.Surface):
        surface.blit(self.image, self.rect)
