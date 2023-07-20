from gymnasium import register
from .settings.constants import MAX_TIMESTEPS

register(
    id='TronLightCycles-v0',
    entry_point='games.tron_light_cycles.env:TronLightCyclesEnv',
    max_episode_steps=MAX_TIMESTEPS
)