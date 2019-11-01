#! /bin/bash

set -x

MODEL_NAME=${1:-face-detection-retail-0004}
MODEL_TYPE=FP16
DOWNLOAD_DIR=models

extensions=("bin" "xml")
for ext in ${extensions[@]}; do
  url=https://download.01.org/opencv/2019/open_model_zoo/R3/20190905_163000_models_bin/${MODEL_NAME}/${MODEL_TYPE}/${MODEL_NAME}.${ext}
  wget -c  -P $DOWNLOAD_DIR $url
done

echo "done"
