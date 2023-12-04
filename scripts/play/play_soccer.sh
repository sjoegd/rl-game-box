#!/bin/bash

python scripts/sb3_play.py \
    --env_path="games/Soccer/builds/soccer_sync_play.exe" \
    --agents_per_env=2 \
    --action_repeat=4 \
    --load_model_paths="models/Soccer/Soccer_0/Soccer_0" \
    --num_episodes=5 \