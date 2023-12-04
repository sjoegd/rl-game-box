#!/bin/bash

python scripts/sb3_test.py \
    --env_path="games/Racing/builds/racing_sync.x86_64" \
    --agents_per_env=4 \
    --action_repeat=8 \
    --load_model_paths="models/Racing/Racing_1/Racing_1, models/Racing/Racing_1/Racing_1" \
    --num_episodes=5 \