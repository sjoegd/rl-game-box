# TESTING

from tank import Tank
import pygame

pygame.init()

screen = pygame.display.set_mode((800, 600))
clock = pygame.time.Clock()

body_image = pygame.image.load("assets/battle-tanks/images/tanks/body_red.png")
turret_image = pygame.image.load("assets/battle-tanks/images/tanks/turret_red_with_offset.png")

tank = Tank(400, 300, body_image, turret_image)

# Main game loop
running = True
while running:
    # Handle events
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False

    keys = pygame.key.get_pressed()
    tank.forward = keys[pygame.K_w]
    tank.backward = keys[pygame.K_s]
    tank.right = keys[pygame.K_d]
    tank.left = keys[pygame.K_a]

    tank.update()

    # Update the screen
    screen.fill((255, 255, 255))
    tank.draw(screen)
    pygame.display.flip()

    # Limit the frame rate
    clock.tick(60)

# Quit the game
pygame.quit()
