#!/bin/bash

python scripts/sb3_train.py \
    --is_async=True \
    --env_path="games/Soccer/builds/soccer_sync.x86_64" \
    --save_parent_folder_path="models/Soccer/Soccer_0" \
    --save_model_name="Soccer_0" \
    --speedup=12 \
    --agents_per_env=2 \
    --n_parallel=4 \
    --action_repeat=4 \
    --max_past_agents=50 \
    --total_timesteps=2_500_000 \
    --total_iterations=50 \