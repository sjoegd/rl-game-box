#!/bin/bash

python scripts/sb3_test.py \
    --env_path="games/Racing/builds/racing_test.exe" \
    --model_paths="models/Racing/Racing_1/Racing_1, models/Racing/Racing_0/Racing_0" \
    --agents_per_env=4 \
    --action_repeat=8 \
    --sessions=5 \