#!/bin/bash

python scripts/sb3_train.py \
    --env_path="games/Soccer/builds/soccer_train.x86_64" \
    --save_parent_folder_path="models/Soccer/Soccer_0" \
    --save_model_name="Soccer_0" \
    --speedup=16 \
    --agents_per_env=4 \
    --games_per_env=4 \
    --n_parallel=4 \
    --action_repeat=8 \
    --max_past_agents=25 \
    --total_timesteps=10_000_000 \
    --total_iterations=100 \