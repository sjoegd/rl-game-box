#!/bin/bash

python scripts/sb3_test.py \
    --env_path="games/Soccer/builds/soccer_test.exe" \
    --model_paths="models/Soccer/Soccer_0/Soccer_0, models/Soccer/Soccer_0/Soccer_0" \
    --agents_per_env=4 \
    --action_repeat=8 \
    --sessions=5 \