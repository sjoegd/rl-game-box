#!/bin/bash

python scripts/sb3_train.py \
    --env_path="games/Racing/builds/racing_train.x86_64" \
    --save_parent_folder_path="models/Racing/Racing_2" \
    --save_model_name="Racing_2" \
    --speedup=12 \
    --agents_per_env=4 \
    --games_per_env=4 \
    --n_parallel=2 \
    --action_repeat=8 \
    --max_past_agents=50 \
    --total_timesteps=2_500_000 \
    --total_iterations=50 \