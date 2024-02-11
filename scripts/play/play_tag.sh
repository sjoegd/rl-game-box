#!/bin/bash

python scripts/sb3_play.py \
    --env_path="games/Tag/builds/tag_play.exe" \
    --model_paths="models/Tag/Tag_0/Tag_0" \
    --agents_per_env=4 \
    --action_repeat=8 \
    --sessions=5 \