#!/bin/bash

python scripts/sb3_play.py \
    --env_path="games/Racing/builds/racing_sync_play.exe" \
    --agents_per_env=4 \
    --action_repeat=8 \
    --load_model_paths="models/Racing/Racing_1/Racing_1" \
    --num_episodes=5 \