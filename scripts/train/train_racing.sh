#!/bin/bash

python scripts/sb3_train.py \
    --is_async=True \
    --env_path="games/Racing/builds/racing.x86_64" \
    --save_parent_folder_path="models/Racing/Racing_0" \
    --save_model_name="Racing_0" \
    --speedup=12 \
    --agents_per_env=6 \
    --n_parallel=4 \
    --action_repeat=8 \
    --max_past_agents=25 \
    --total_timesteps=1_000_000 \
    --total_iterations=100 \