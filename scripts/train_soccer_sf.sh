#!/bin/sh
gdrl --trainer=sf --env=gdrl --env_path=games/Soccer/build/soccer_train.x86_64 --num_workers=10 --experiment_name=Soccer_0 \
 --speedup=12 --num_policies=2 --env_agents=2 --batch_size=2048 --num_batches_per_epoch=2 --async_rl=True --batched_sampling=False \
 --num_epochs=10 --learning_rate=0.00005 --exploration_loss_coef=0.001 --lr_schedule=kl_adaptive_epoch --lr_schedule_kl_threshold=0.08 --use_rnn=True --recurrence=32 \
 --train_for_env_steps=10_000_000 --load_checkpoint_kind=latest --save_every_sec=30 --pbt_mix_policies_in_one_env=True


