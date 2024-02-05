#!/bin/bash

python scripts/sb3_train.py \
    --resume_training=True \
    --env_path="games/Soccer/builds/soccer_train.x86_64" \
    --save_parent_folder_path="models/Soccer/Soccer_0" \
    --save_model_name="Soccer_0" \
