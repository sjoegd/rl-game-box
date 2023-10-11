#!/bin/sh
python scripts/sb3_train.py --env_path=games/Soccer/build/soccer_train.x86_64 --save_parent_folder_path=models/Soccer/Soccer_0 \
 --save_model_name=Soccer_0 --speedup=12 --agents_per_env=2 --n_parallel=4 --max_past_agents=25 --total_timesteps=10_000_000 \
 --total_iterations=250 --action_repeat=4 --is_async=True
