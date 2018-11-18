#!/usr/bin/env bash


DOCKER_IMAGE="fbarmes/rpi-mariadb"
CONTAINER_NAME="rpi-mariadb"
DOCKER_RUN_OPT="-d"

#-------------------------------------------------------------------------------
# structure
#-------------------------------------------------------------------------------
mkdir -p /opt/docker/data/${CONTAINER_NAME}

#-------------------------------------------------------------------------------
# run container
#-------------------------------------------------------------------------------
docker run \
  ${DOCKER_RUN_OPT} \
  --name ${CONTAINER_NAME} \
  --hostname ${CONTAINER_NAME} \
  -p 3306:3306 \
  -v /opt/docker/data/${CONTAINER_NAME}:/data/mysql \
  ${DOCKER_IMAGE}
