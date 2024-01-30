#!/bin/bash

python scripts/sb3_test.py \
    --env_path="games/Racing/builds/racing_test.exe" \
    --model_paths="models/Racing/Racing_4/Racing_4, models/Racing/Racing_4/Racing_4" \
    --agents_per_env=4 \
    --action_repeat=8 \
    --sessions=5 \