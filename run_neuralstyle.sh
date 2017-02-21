#!/bin/bash -xe

# https://github.com/jcjohnson/neural-style
# https://github.com/albarji/neural-style-docker/

CONTENT_IMAGE="alex.jpg"
STYLE_IMAGE="vangogh.jpg"
LOCAL_STYLE_IMAGE="picasso_selfport1907.jpg"
NUM_ITERATIONS=1000
IMAGE_SIZE=512

if [ -z "${CONTENT_IMAGE}" -o ! -f ${CONTENT_IMAGE} ]; then
    echo "Error: file ${CONTENT_IMAGE} not found.";
    exit 1;
fi

echo "DOCKER_MACHINE_NAME = ${DOCKER_MACHINE_NAME}"
read -p "Press any key to start ..."

echo "## Get Models and Styles"
nvidia-docker run \
                -v /tmp/images:/images \
                -v /tmp/models:/neural-style/models \
                --entrypoint /bin/sh \
                -w /neural-style \
                albarji/neural-style \
                    -c "set -ex && apt-get update -y && apt-get install -y subversion && \
                        wget --no-check-certificate https://raw.githubusercontent.com/jcjohnson/neural-style/master/models/download_models.sh -P models && sh ./models/download_models.sh && \
                        svn co https://github.com/albarji/neural-style-docker/trunk/styles /images/styles && \
                        svn co https://github.com/albarji/neural-style-docker/trunk/contents /images/contents && \
                        chmod 777 /images/contents /images/styles"

echo "## Push Content"
docker-machine scp ${CONTENT_IMAGE} ${DOCKER_MACHINE_NAME}:/tmp/images/contents/
if [ ! -z "${LOCAL_STYLE_IMAGE}" ]; then
    if [ ! -f ${LOCAL_STYLE_IMAGE} ]; then
        echo "Error: file ${LOCAL_STYLE_IMAGE} not found.";
        exit 1;
    fi
    docker-machine scp ${LOCAL_STYLE_IMAGE} ${DOCKER_MACHINE_NAME}:/tmp/images/styles/;
    STYLE_IMAGE=${LOCAL_STYLE_IMAGE};
fi

echo "## RUN"
OUTPUT_NAME="output_$(date +%s)"
time nvidia-docker run -e TERM=xterm \
                -v /tmp/images:/images \
                -v /tmp/models:/neural-style/models \
                albarji/neural-style \
                    -image_size ${IMAGE_SIZE} \
                    -backend cudnn \
                    -cudnn_autotune \
                    -num_iterations ${NUM_ITERATIONS} \
                    -content_image contents/${CONTENT_IMAGE} \
                    -style_image styles/${STYLE_IMAGE} \
                    -output_image ${OUTPUT_NAME}.png \
                    -save_iter 0

read -p "Press any key to continue ..."

mkdir ${OUTPUT_NAME} && docker-machine scp ${DOCKER_MACHINE_NAME}:/tmp/images/${OUTPUT_NAME}* ${OUTPUT_NAME}