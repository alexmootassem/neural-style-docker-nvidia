#!/bin/bash -xe

# https://github.com/NVIDIA/nvidia-docker/

MACHINE_NAME=$(openssl rand -hex 8)
AWS_VPC_ID="vpc-xxxxxxxx"
AWS_TYPE="g2.2xlarge"
AWS_AMI="ami-5524e543" # Custom built AMI, see: https://github.com/NVIDIA/nvidia-docker/wiki/Deploy-on-Amazon-EC2
AWS_REGION="us-east-1"
AWS_REGION_ZONE="c"

docker-machine create --driver amazonec2 \
                        --amazonec2-region ${AWS_REGION} \
                        --amazonec2-zone ${AWS_REGION_ZONE} \
                        --amazonec2-ami ${AWS_AMI} \
                        --amazonec2-instance-type ${AWS_TYPE} \
                        --amazonec2-vpc-id ${AWS_VPC_ID} \
                        ${MACHINE_NAME}

read -p "Press any key to continue ...";

eval `docker-machine env ${MACHINE_NAME}`;
export NV_HOST="ssh://ubuntu@$(docker-machine ip ${MACHINE_NAME}):";
eval `ssh-agent -s`;
ssh-add ~/.docker/machine/machines/${MACHINE_NAME}/id_rsa;

echo "# Test running: nvidia-docker run --rm nvidia/cuda nvidia-smi"
