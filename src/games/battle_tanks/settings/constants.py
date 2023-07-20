import math
import pymunk

# ---------- MISC ---------- #
FPS = 60

# ---------- TANKS ---------- #
TANK_SCALE          = 0.4
TANK_SPEED          = 7.5 * TANK_SCALE
TANK_ROTATE_SPEED   = math.radians(3)
TURRET_ROTATE_SPEED = math.radians(5)
TURRET_BODY_OFFSET  = pymunk.Vec2d(0, 35) * TANK_SCALE

# ---------- ROCKETS ---------- #
ROCKET_SCALE  = 1.75
ROCKET_SPEED  = 30 * TANK_SCALE
ROCKET_DAMAGE = 25

# ---------- EXPLOSIONS ---------- #
ROCKET_EXPLOSION_INFO = ("rocket", ROCKET_SCALE/1.75, 8)
TANK_EXPLOSION_INFO   = ("tank",   TANK_SCALE*1.5,    9)

# ---------- MAP ---------- #
MAP_SCALE        = 3
TILE_COLUMNS     = 50
TILE_ROWS        = 25
TILE_SIZE        = 8
SCALED_TILE_SIZE = TILE_SIZE * MAP_SCALE
MAP_WIDTH        = TILE_COLUMNS * SCALED_TILE_SIZE
MAP_HEIGHT       = TILE_ROWS * SCALED_TILE_SIZE

# ---------- COLLISION TYPES ---------- #
TANK_COLLISION_TYPE   = 1
TILE_COLLISION_TYPE   = 2
ROCKET_COLLISION_TYPE = 3

# ---------- COLLISION MASKS ---------- #
TANK_RED_MASK    = 0b000001
TANK_BLUE_MASK   = 0b000010
ROCKET_RED_MASK  = 0b000100
ROCKET_BLUE_MASK = 0b001000
TILE_MASK        = 0b010000