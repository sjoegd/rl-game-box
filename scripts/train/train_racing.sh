#!/bin/bash

python scripts/sb3_train_single.py \
    --env_path="games/Racing/builds/racing_single.x86_64" \
    --n_parallel=4 \
    --speedup=12 \
    --action_repeat=4 \
    --timesteps=10_000_000 \
    --save_model_path="models/Racing/Racing_0"
