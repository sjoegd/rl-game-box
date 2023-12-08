#!/bin/bash

python scripts/sb3_test.py \
    --env_path="games/Soccer/builds/soccer_test.exe" \
    --model_paths="models/Soccer/Soccer_0/Soccer_0" \
    --agents_per_env=2 \
    --action_repeat=6 \
    --sessions=5 \