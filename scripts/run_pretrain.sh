#!/bin/bash

export CUDA_VISIBLE_DEVICES=2
export TOKENIZERS_PARALLELISM=true
export OMP_NUM_THREADS=4
dt=`date '+%Y%m%d_%H%M%S'`


dataset="csqa"
shift
encoder='roberta-large'
args=$@


elr="1e-5"
dlr="1e-3"
bs=128
mbs=2
unfreeze_epoch=3
k=5 #num of gnn layers
residual_ie=2
gnndim=200


encoder_layer=-1
max_node_num=200
seed=5
lr_schedule=warmup_linear
warmup_steps=100

n_epochs=30
max_epochs_before_stop=30
ie_dim=400


max_seq_len=100
ent_emb=data/cpnet/tzw.ent.npy
kg=cpnet
kg_vocab_path=data/cpnet/concept.txt
inhouse=true


info_exchange=true
ie_layer_num=1
resume_checkpoint=None
resume_id=None
sep_ie_layers=false
random_ent_emb=false

fp16=true
upcast=true

load_model_path=None

end_task=0
mlm_task=1
link_task=1

mlmp=0.15

ldrpc=100
ldrpp=0.15
ldrppk=0.1
negs=64
normht=3
scldstmlt=true
projHT=false

kgd="DistMult"
gamma=0

echo "***** hyperparameters *****"
echo "dataset: $dataset"
echo "enc_name: $encoder"
echo "batch_size: $bs mini_batch_size: $mbs"
echo "learning_rate: elr $elr dlr $dlr"
echo "gnn: dim $gnndim layer $k"
echo "ie_dim: ${ie_dim}, info_exchange: ${info_exchange}"
echo "kgd: ${kgd}"
echo "******************************"

#save_dir_pref='runs'
save_dir_pref='pretrain'
mkdir -p $save_dir_pref
mkdir -p logs

run_name=v3.1_dragon__${dataset}__${dt}
log=logs/pretrain__${run_name}.log.txt

###### Training ######
python3 -u dragon.py \
    --dataset $dataset \
    --encoder $encoder -k $k --gnn_dim $gnndim -elr $elr -dlr $dlr -bs $bs --seed $seed -mbs ${mbs} --unfreeze_epoch ${unfreeze_epoch} --encoder_layer=${encoder_layer} -sl ${max_seq_len} --max_node_num ${max_node_num} \
    --n_epochs $n_epochs --max_epochs_before_stop ${max_epochs_before_stop} --fp16 $fp16 --upcast $upcast --use_wandb false \
    --end_task $end_task --mlm_task $mlm_task --link_task $link_task \
    --mlm_probability $mlmp \
    --link_drop_max_count $ldrpc --link_drop_probability $ldrpp --link_drop_probability_in_which_keep $ldrppk --link_negative_sample_size $negs --link_normalize_headtail $normht --link_proj_headtail $projHT --scaled_distmult $scldstmlt --link_decoder $kgd --link_gamma $gamma \
    --save_dir ${save_dir_pref}/${dataset}/${run_name} --save_model 2 \
    --run_name ${run_name} \
    --load_model_path $load_model_path \
    --residual_ie $residual_ie \
    --ie_dim ${ie_dim} --info_exchange ${info_exchange} --ie_layer_num ${ie_layer_num} --resume_checkpoint ${resume_checkpoint} --resume_id ${resume_id} --sep_ie_layers ${sep_ie_layers} --random_ent_emb ${random_ent_emb} --ent_emb_paths ${ent_emb//,/ } --lr_schedule ${lr_schedule} --warmup_steps $warmup_steps -ih ${inhouse} --kg $kg --kg_vocab_path $kg_vocab_path \
    --data_dir data \
> ${log}
