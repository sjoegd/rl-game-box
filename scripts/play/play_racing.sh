#!/bin/bash

python scripts/sb3_play.py \
    --env_path="games/Racing/builds/racing_play.exe" \
    --model_paths="models/Racing/Racing_1/Racing_1" \
    --agents_per_env=4 \
    --action_repeat=8 \
    --sessions=5 \