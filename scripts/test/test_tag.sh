#!/bin/bash

python scripts/sb3_test.py \
    --env_path="games/Tag/builds/tag_test.exe" \
    --model_paths="models/Tag/Tag_0/Tag_0, models/Tag/Tag_0/Tag_0" \
    --agents_per_env=4 \
    --action_repeat=8 \
    --sessions=5 \