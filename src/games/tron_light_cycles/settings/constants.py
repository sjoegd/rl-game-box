import math

# --------- Map ---------- #
MAP_WIDTH  = 1280
MAP_HEIGHT = 720

# --------- Misc ---------- #
FPS = 60
FRAME_SKIP = 4
MAX_TIMESTEPS = 1000

# --------- Positions ---------- #
CYCLE_1_POSITION = (MAP_HEIGHT * 0.2, MAP_HEIGHT * 0.2)
CYCLE_2_POSITION = (MAP_WIDTH - (MAP_HEIGHT * 0.2), MAP_HEIGHT * 0.8)
CYCLE_1_ANGLE = math.pi
CYCLE_2_ANGLE = 0

# --------- Cycle ---------- #
CYCLE_SCALE = 0.15

# --------- Trail ---------- #
TRAIL_RADIUS = 4 * (CYCLE_SCALE / 0.15)

# --------- Collision Types ---------- #
COLLISION_TYPE_CYCLE = 1
COLLISION_TYPE_TRAIL = 2
COLLISION_TYPE_WALL  = 3

# --------- Collision Masks ---------- #
MASK_CYCLE_BLUE = 0b0001
MASK_CYCLE_RED  = 0b0010
MASK_TRAIL      = 0b0100
MASK_WALL       = 0b1000