#!/bin/bash

python scripts/sb3_test.py \
    --env_path="games/Racing/builds/racing.x86_64" \
    --agents_per_env=6 \
    --action_repeat=8 \
    --load_model_paths="models/Racing/Racing_0/Racing_0, models/Racing/Racing_0/Racing_0" \
    --num_episodes=5 \