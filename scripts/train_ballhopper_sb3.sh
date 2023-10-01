#!/bin/sh
python scripts/stable_baselines3_train.py --env_path=games/BallHopper/build/ballhopper_train.x86_64 --n_parallel=4 \
 --speedup=12 --experiment_name="BallHopper_0" --timesteps=1_000_000 --save_model_path=models/BallHopper/BallHopper_0 