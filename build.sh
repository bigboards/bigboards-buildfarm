#!/bin/bash
# -- ----------------------------------------------------------------------- --
# -- build.sh - the buildscript for the bigboards buildfarm
# -- ----------------------------------------------------------------------- --
set -eo pipefail

PROJECT=$1
BRANCH=$2

[[ $BUILDKITE_BRANCH == 'master' ]] && TAG=latest || TAG=$BUILDKITE_BRANCH

sed -i "s/__arch__/$(uname -m)/g" Dockerfile
docker build -t bigboards/${PROJECT}-$(uname -m):$TAG .
docker login -u bigboards -p 1nktv1sjeS
docker push bigboards/${PROJECT}-$(uname -m):$TAG
