#!/usr/bin/env bash

set -xau
DIRPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source ${DIRPATH}/VERSIONS

BOSH_RELEASE_NAME="$(bosh int config/final.yml --path /name)"
APP_RELEASE_NAME="${BOSH_RELEASE_NAME}_${KAFKA_VERSION}"

pushd ${DIRPATH}
  fly -t ${CONCOURSE_TARGET:-prodSmarsh} sp \
    -p ds-kafka-bosh-release \ 
    -c pipeline.yml \
    -l settings.yml \
    -v bosh-release-name="${BOSH_RELEASE_NAME}" \
    -v app-release-name="${APP_RELEASE_NAME}"
popd
