#!/usr/bin/env bash

set -euo pipefail

if [[ $(echo $TERM | grep -v xterm) ]]; then
  export TERM=xterm
fi

SHELL=/bin/bash
ROOT_DIR=$(pwd)
USE_PIPELINE=0
INPUT_DIR=pull-request
OUTPUT_DIR=create-dev-release
SOURCE_DL_DIR=.downloads
BOSH_RELEASE_VERSION_FILE=../version/version
SOURCE_VERSION_FILE="$(pwd)/VERSIONS"

BOLD=$(tput bold)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
MAGENTA=$(tput setaf 5)
RESET=$(tput sgr0)

[[ -f ${SOURCE_VERSION_FILE} ]] && source ${SOURCE_VERSION_FILE}
KAFKA_VERSION=${KAFKA_VERSION:?required}
KAFKA_MANAGER_VERSION=${KAFKA_MANAGER_VERSION:?required}
JAVA_VERSION=${JAVA_VERSION:?required}

if [[ ! -f  ${BOSH_RELEASE_VERSION_FILE} ]] ; then
  BOSH_RELEASE_VERSION=$(cat ${BOSH_RELEASE_VERSION_FILE})
else 
  BOSH_RELEASE_VERSION=${KAFKA_VERSION}
fi

declare -A downloads
downloads[kafka/kafka_2.12-${KAFKA_VERSION}.zip]="https://downloads.apache.org/kafka/${KAFKA_VERSION}/kafka_2.12-${KAFKA_VERSION}.tgz"
downloads[kafka/kafka-manager-${KAFKA_MANAGER_VERSION}.tgz]="https://codeload.github.com/yahoo/CMAK/tar.gz/${KAFKA_MANAGER_VERSION}"
downloads[java/jdk${JAVA_VERSION}.tar.gz]="https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u252-b09/OpenJDK8U-jdk_x64_linux_hotspot_${JAVA_VERSION/-/}.tar.gz"


download() {
  local file=${1}
  local url=${2}

  printf "\n${BOLD}${GREEN}Downloading ${url} ...${RESET}\n"
  curl --fail -L -o $file $url 
}

addBlob() {
  local path=${1}
  local blobPath=${2}

  printf "\n${BOLD}${GREEN}Track blob ${blobPath} for inclusion in release${RESET}\n"
  bosh add-blob $path ${blobPath}
}

main() {
  [[ ! -d ${SOURCE_DL_DIR} ]] && mkdir ${SOURCE_DL_DIR}

  if [[ ! -d ../${OUTPUT_DIR} ]] ; then 
    tarBallPath=${SOURCE_DL_DIR}/kafka-${BOSH_RELEASE_VERSION}.tgz
  else
    tarBallPath=../${OUTPUT_DIR}/kafka-${BOSH_RELEASE_VERSION}.tgz
  fi

  # remove blobs
  > config/blobs.yml
  
  for key in "${!downloads[@]}" 
  do
    local file=${SOURCE_DL_DIR}/$(basename ${key})
    local blobPath=${key}

    download ${file} ${downloads[${key}]}
    addBlob ${file} ${blobPath}

  done
  
  printf "\n${BOLD}${GREEN}Create release${RESET}\n"
  
  # fix - removing .final_builds folder is not necessary when running locally however when running in a pipeline 
  # which uses bosh version 6.2.1 bosh create-release --force fails
  # that requires this hidden directory to be renamed/removed
  [[ $USE_PIPELINE -ne 0 ]] && rm -fr .final_builds
  bosh create-release --force --name kafka --version=${BOSH_RELEASE_VERSION} --timestamp-version --tarball=${tarBallPath}
}

bosh reset-release
main
