#!/bin/bash

python scripts/sb3_train.py \
    --env_path="games/Soccer/builds/soccer_train.x86_64" \
    --save_parent_folder_path="models/Soccer/Soccer_0" \
    --save_model_name="Soccer_0" \
    --speedup=12 \
    --agents_per_env=2 \
    --games_per_env=8 \
    --n_parallel=1 \
    --action_repeat=4 \
    --max_past_agents=50 \
    --total_timesteps=2_500_000 \
    --total_iterations=50 \