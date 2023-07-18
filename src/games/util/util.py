from csv import reader
from pathlib import Path
import pygame

def scale_image(surface: pygame.Surface, scale: float):
    width = int(surface.get_width() * scale)
    height = int(surface.get_height() * scale)
    return pygame.transform.scale(surface, (width, height))

def load_images_from_sheet(sheet: pygame.Surface, width: int, height: int) -> list[pygame.Surface]:
    col_size = sheet.get_width() // width
    row_size = sheet.get_height() // height
    images = []
    
    for row in range(row_size):
        for column in range(col_size):
            x = column * width
            y = row * height
            image = sheet.subsurface(x, y, width, height)
            images.append(image)
    
    return images

def load_csv(file: str) -> list[str]:
    file = Path(file)
    csv = []
    with open(file, "r") as f:
        data = reader(f)
        csv.extend(list(row) for row in data)
        return csv

def conditional_convert_alpha(surface: pygame.Surface, should_convert: False) -> pygame.Surface:
    return surface.convert_alpha() if should_convert else surface.convert()