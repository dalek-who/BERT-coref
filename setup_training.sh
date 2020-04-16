#!/bin/bash
# 这个脚本主要包括两部分内容：下载未fineturn的参数，处理Ontonotes数据集
# 其中处理ontonotes数据集又分为两步：1.把原始数据集处理为conll格式。2.把conll格式处理为bert使用的jsonlines格式
# 因此，evaluation之前也需要用这个脚本处理数据集
# 这个脚本中有的地方需要用python 2.x有的地方需要3.x，不能一次性自动执行完，可能需要执行错误后手动切换环境，运行剩余部分

ontonotes_path=$1
data_dir=$2

dlx() {
  wget -P $data_dir $1/$2
  tar -xvzf $data_dir/$2 -C $data_dir
  rm $data_dir/$2
}

download_bert(){
  model=$1
  wget -P $data_dir https://storage.googleapis.com/bert_models/2018_10_18/$model.zip
  unzip $data_dir/$model.zip
  rm $data_dir/$model.zip
  mv $model $data_dir/
}

download_spanbert(){
  model=$1
  wget -P $data_dir https://dl.fbaipublicfiles.com/fairseq/models/$model.tar.gz
  mkdir $data_dir/$model
  tar xvfz $data_dir/$model.tar.gz -C $data_dir/$model
  rm $data_dir/$model.tar.gz
}

# 必须先下载这些配套文件后，才能正常运行下面的conll转换脚本
conll_url=http://conll.cemantix.org/2012/download
dlx $conll_url conll-2012-train.v4.tar.gz
dlx $conll_url conll-2012-development.v4.tar.gz
dlx $conll_url/test conll-2012-test-key.tar.gz
dlx $conll_url/test conll-2012-test-official.v9.tar.gz

dlx $conll_url conll-2012-scripts.v3.tar.gz
dlx http://conll.cemantix.org/download reference-coreference-scorers.v8.01.tar.gz

# 把原始ontonetes数据集处理为conll格式，这一步需要用python 2.x运行，3.x运行不了
bash conll-2012/v3/scripts/skeleton2conll.sh -D $ontonotes_path/data/files/data $data_dir/conll-2012

function compile_partition() {
    rm -f $2.$5.$3$4
    cat $data_dir/conll-2012/$3/data/$1/data/$5/annotations/*/*/*/*.$3$4 >> $data_dir/$2.$5.$3$4
}

function compile_language() {
    compile_partition development dev v4 _gold_conll $1
    compile_partition train train v4 _gold_conll $1
    compile_partition test test v4 _gold_conll $1
}

compile_language english
#compile_language chinese
#compile_language arabic

# 把conll格式处理成bert的输入。前面用的是python2.x 这步需要切换回项目本身的python环境
vocab_file=cased_config_vocab/vocab.txt
python minimize.py $vocab_file $data_dir $data_dir false


##############################################################
# 下载未fineturn的bert参数
download_bert cased_L-12_H-768_A-12
download_bert cased_L-24_H-1024_A-16
download_spanbert spanbert_hf
download_spanbert spanbert_hf_base
##############################################################
