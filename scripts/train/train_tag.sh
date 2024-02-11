#!/bin/bash

python scripts/sb3_train.py \
    --env_path="games/Tag/builds/tag_train.x86_64" \
    --save_parent_folder_path="models/Tag/Tag_0" \
    --save_model_name="Tag_0" \
    --speedup=12 \
    --agents_per_env=4 \
    --games_per_env=1 \
    --n_parallel=4 \
    --action_repeat=8 \
    --max_past_agents=25 \
    --total_timesteps=10_000_000 \
    --total_iterations=100 \