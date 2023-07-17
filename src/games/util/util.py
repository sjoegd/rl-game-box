import pygame


def scale_surface(surface: pygame.Surface, scale: float):
    width = int(surface.get_width() * scale)
    height = int(surface.get_height() * scale)
    return pygame.transform.scale(surface, (width, height))