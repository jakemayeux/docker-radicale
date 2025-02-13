#!/bin/bash

set -eo pipefail

# Login to Docker
echo "$DOCKER_PWD" | docker login -u "$DOCKER_USER" --password-stdin

# Require to build docker image of other architectures
docker run --rm --privileged multiarch/qemu-user-static:register --reset

if [ -z "$TRAVIS_TAG" ]
then
  DOCKERFILE_SUFFIX=""
  DOCKER_TAG="latest"
else
  DOCKERFILE_SUFFIX=".$TRAVIS_TAG"
  DOCKER_TAG="$TRAVIS_TAG"
fi

archs=(amd64 arm64)

for arch in "${archs[@]}"
do
  case "$arch" in
    amd64 ) base_image="alpine:3.14" ;;
    arm64 ) base_image="balenalib/aarch64-alpine:3.14" ;;
  esac

  sed "1cFROM $base_image" Dockerfile > "Dockerfile.$arch"

  docker build \
    --build-arg COMMIT_ID=$TRAVIS_COMMIT \
    -t tomsquest/docker-radicale:$arch$DOCKERFILE_SUFFIX \
    --file Dockerfile.$arch .

  docker push tomsquest/docker-radicale:$arch$DOCKERFILE_SUFFIX
done

# Docker Manifest is experimental, need to enable it manually
export DOCKER_CLI_EXPERIMENTAL=enabled

docker manifest create tomsquest/docker-radicale:$DOCKER_TAG \
  tomsquest/docker-radicale:amd64$DOCKERFILE_SUFFIX \
  tomsquest/docker-radicale:arm64$DOCKERFILE_SUFFIX

docker manifest annotate tomsquest/docker-radicale:$DOCKER_TAG \
  tomsquest/docker-radicale:amd64$DOCKERFILE_SUFFIX --arch amd64
docker manifest annotate tomsquest/docker-radicale:$DOCKER_TAG \
  tomsquest/docker-radicale:arm64$DOCKERFILE_SUFFIX --arch arm64

docker manifest push tomsquest/docker-radicale:$DOCKER_TAG
