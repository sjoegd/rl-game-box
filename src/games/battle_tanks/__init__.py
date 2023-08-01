from gymnasium import register
from .settings.constants import MAX_TIMESTEPS

register(
    id='BattleTanks-v0',
    entry_point='games.battle_tanks.env:BattleTanksEnv',
    max_episode_steps=MAX_TIMESTEPS
)