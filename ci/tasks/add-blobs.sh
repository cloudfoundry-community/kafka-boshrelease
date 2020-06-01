#!/usr/bin/env bash

set -euo pipefail

if [[ $(echo $TERM | grep -v xterm) ]]; then
  export TERM=xterm
fi

SHELL=/bin/bash
ROOT_DIR=$(pwd)
OUTPUT_DIR=add-blobs
SOURCE_DL_DIR=.downloads
BOSH_RELEASE_VERSION_FILE=../version/number
SOURCE_VERSION_FILE="$(pwd)/ci/VERSIONS"
RELEASE_NAME=$(bosh int config/final.yml --path /final_name)
BOSH_RELEASE_FILE=${RELEASE_NAME}-${BOSH_RELEASE_VERSION}.tgz
PRERELEASE_REPO=../git-prerelease-repo
RUN_PIPELINE=0 # if script is running locally then 0 if in consourse pipeline then 1

BOLD=$(tput bold)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
MAGENTA=$(tput setaf 5)
RESET=$(tput sgr0)


logerror() {
  echo
  echo 1>&2 "###"
  echo 1>&2 "###"
  printf "### ${BOLD}${RED}${1}${RESET}\n" 1>&2
  echo 1>&2 "###"
  echo 1>&2
}

loginfo() {
  echo
  echo "###"
  echo "###"
  printf "### ${BOLD}${GREEN}${1}${RESET}\n"
  echo "###"
  echo
}

download() {
  local file=${1}
  local url=${2}

  loginfo "Downloading ${url} ..."
  curl --fail -L -o $file $url 
}

addBlob() {
  local path=${1}
  local blobPath=${2}

  loginfo "Track blob ${blobPath} for inclusion in release"
  bosh add-blob $path ${blobPath}
}

main() {

  if [[ -f ${SOURCE_VERSION_FILE} ]] ; then 
    source ${SOURCE_VERSION_FILE}
    if [[ -f ci/dl-packages-src ]] ; then
      source ci/dl-packages-src
    else
      logerror "Missing local versioning file in ci/dl-packages-src"
      exit 2
    fi
  else
    logerror "Missing source download file in ci/VERSIONS"
    exit 2
  fi


  # Are we running inside a concourse pipeline
  # i wonder if theres something else i can use
  if [[ -f  ${BOSH_RELEASE_VERSION_FILE} ]] ; then
    BOSH_RELEASE_VERSION=$(cat ${BOSH_RELEASE_VERSION_FILE})
    RUN_PIPELINE=1
  else 
    BOSH_RELEASE_VERSION='SNAPSHOT'
  fi

  [[ ! -d ${SOURCE_DL_DIR} ]] && mkdir ${SOURCE_DL_DIR}
  
  for key in "${!downloads[@]}" 
  do
    local file=${SOURCE_DL_DIR}/$(basename ${key})
    local blobPath=${key}

    download ${file} ${downloads[${key}]}

  done
  
  # remove blobs
  > config/blobs.yml

  for key in "${!downloads[@]}" 
  do
    local file=${SOURCE_DL_DIR}/$(basename ${key})
    local blobPath=${key}

    addBlob ${file} ${blobPath}

  done

  rm -fr ${SOURCE_DL_DIR}


  if [[ ${RUN_PIPELINE} -eq 1 ]] ; then

    loginfo "Create release version ${BOSH_RELEASE_VERSION}"
    
    # fix - removing .final_builds folder is not necessary when running locally however when running in a pipeline 
    # which uses bosh version 6.2.1 bosh create-release --force fails
    # that requires this hidden directory to be renamed/removed
    rm -fr .final_builds
    
    BRANCH=$(git name-rev --name-only $(git rev-list  HEAD --date-order --max-count 1))

    git status
    
    git checkout ${BRANCH}

    tarBallPath=${OUTPUT_DIR}/${BOSH_RELEASE_FILE}

    loginfo "Create release version ${BOSH_RELEASE_VERSION}"
    bosh create-release --force --name ${RELEASE_NAME} --version=${BOSH_RELEASE_VERSION} --timestamp-version --tarball=${tarBallPath}
    
    
    cat << EOF > config/final.yml
---
blobstore:
  provider: s3
  options:
    bucket_name: ${BLOBSTORE}
final_name: ${RELEASE_NAME}
EOF

## Create private.yml for BOSH to use our AWS keys
    cat << EOF > config/private.yml
---
blobstore:
  provider: s3
  options:
    credentials_source: env_or_profile
EOF

  loginfo "Upload blobs ${BOSH_RELEASE_VERSION}"
  bosh blobs
  bosh -n upload-blobs
  
    if [[ -n "$(git status --porcelain)" ]]; then

      git config --global user.email "CI@localhost"
      git config --global user.name "CI Bot "

      git status
      git update-index --assume-unchanged config/final.yml
      git add -A
      git status
      git commit -m "Adding blob, ${BOSH_RELEASE_FILE} to ${BLOBSTORE} via concourse"
      [[ -d ${PRERELEASE_REPO} ]] && mkdir -p ${PRERELEASE_REPO}
      cp -r . ${PRERELEASE_REPO}
    fi
  fi

}

bosh reset-release
main
