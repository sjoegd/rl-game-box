#!/bin/bash

python scripts/sb3_train.py \
    --resume_training=True \
    --env_path="games/Racing/builds/racing_train.x86_64" \
    --save_parent_folder_path="models/Racing/Racing_1" \
    --save_model_name="Racing_1" \
