import math
import pymunk

# ---------- TANKS ---------- #
TANK_SCALE = 0.75
TANK_SPEED = 5 * TANK_SCALE
TANK_ROTATE_SPEED = math.radians(3)
TURRET_ROTATE_SPEED = math.radians(5)
TURRET_BODY_OFFSET = pymunk.Vec2d(0, 25) * TANK_SCALE

# ---------- BULLETS ---------- #

# ---------- MAP ---------- #

# ---------- COLLISION TYPES ---------- #
TANK_COLLISION_TYPE   = 1
TILE_COLLISION_TYPE   = 2
BULLET_COLLISION_TYPE = 3

# ---------- COLLISION MASKS ---------- #
TANK_RED_MASK    = 0b000001
TANK_BLUE_MASK   = 0b000010
BULLET_RED_MASK  = 0b000100
BULLET_BLUE_MASK = 0b001000
TILE_MASK        = 0b010000
