#!/bin/sh
gdrl --trainer=sf --env=gdrl --env_path=games/Soccer/build/soccer_train.x86_64 --num_workers=10 --experiment_name=Soccer_0 \
 --speedup=15 --num_policies=2 --env_agents=2 --batch_size=1024 --num_batches_per_epoch=2 --batched_sampling=False \
 --num_epochs=2 --restart_behavior=resume --num_envs_per_worker=2 --learning_rate=0.00005 --exploration_loss_coef=0.001 --lr_schedule=kl_adaptive_epoch \
 --lr_schedule_kl_threshold=0.08 --use_rnn=True --recurrence=32 --train_for_env_steps=10_000_000 --load_checkpoint_kind=latest --save_every_sec=30 \
 --with_pbt=True --pbt_period_env_steps=1_000_000 --pbt_start_mutation=1_000_000 --pbt_mix_policies_in_one_env=True
