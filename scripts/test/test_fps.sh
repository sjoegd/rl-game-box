#!/bin/bash

python scripts/sb3_test.py \
    --env_path="games/FPS/builds/fps_test.exe" \
    --model_paths="models/FPS/FPS_0/FPS_0, models/FPS/FPS_0/FPS_0" \
    --agents_per_env=4 \
    --action_repeat=8 \
    --sessions=5 \