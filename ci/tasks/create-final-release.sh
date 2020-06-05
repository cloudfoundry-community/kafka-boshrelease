#!/bin/bash
set -euo pipefail

SHELL=/bin/bash
ROOT_DIR=$(pwd)

if [[ $(echo $TERM | grep -v xterm) ]]; then
  export TERM=xterm
fi

GITHUB_REPO="git-repo"
BOSH_RELEASE_VERSION=$(cat ${ROOT_DIR}/version/version)
BOSH_RELEASE_VERSION_FILE=../version/number
RELEASE_NAME=$(bosh int ${GITHUB_REPO}/config/final.yml --path /final_name)
BOSH_RELEASE_FILE=${RELEASE_NAME}-${BOSH_RELEASE_VERSION}.tgz
PRERELEASE_REPO=./git-prerelease-repo
RUN_PIPELINE=0 # if script is running locally then 0 if in consourse pipeline then 1

BOLD=$(tput bold)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
MAGENTA=$(tput setaf 5)
RESET=$(tput sgr0)

loginfo() {
  echo
  echo "###"
  echo "###"
  printf "### ${BOLD}${GREEN}${1}${RESET}\n"
  echo "###"
  echo
}

loginfo "Configuring files, keys, certs and directories"

set +x

echo "$jumpbox_key" | jq -r .private_key > jumpbox.key 
echo "$ca_cert" | jq -r .certificate > ca_cert.crt

set -x

loginfo "Configuring BOSH environment"

bosh alias-env $BOSH_ENVIRONMENT -e $BOSH_ENVIRONMENT --ca-cert ${ROOT_DIR}/ca_cert.crt
export BOSH_ALL_PROXY=ssh+socks5://jumpbox@${BOSH_ENVIRONMENT}:22?private-key=${ROOT_DIR}/jumpbox.key

## change directories into the master branch of the repository that is cloned, not the branched clone
pushd $PRERELEASE_REPO

  git config --global user.email "ci@localhost"
  git config --global user.name "CI Bot"

  loginfo "Cutting a final release"

  ## Download all of the blobs and packages from the boshrelease bucket that is read only

      
      cat << EOF > config/final.yml
---
blobstore:
  provider: s3
  options:
    bucket_name: ${BLOBSTORE}
name: ${RELEASE_NAME}
EOF

  ## Create private.yml for BOSH to use our AWS keys
      cat << EOF > config/private.yml
---
blobstore:
  provider: s3
  options:
    credentials_source: env_or_profile
EOF

  git update-index --assume-unchanged config/final.yml

  git status

  loginfo "Create final release"
  bosh finalize-release --version=${BOSH_RELEASE_VERSION} --name=${RELEASE_NAME} --version=${BOSH_RELEASE_VERSION} ../add-blob-release/${BOSH_RELEASE_FILE}

  git status

  git add config .final_builds releases || true
  [[ -n "$(git status --porcelain)" ]] && git commit -am "Final release stage change, ${BOSH_RELEASE_VERSION} via concourse"

  loginfo "Create release final release tarball"
  bosh create-release --tarball=../release-tarball/${BOSH_RELEASE_FILE} --final

  echo "v${BOSH_RELEASE_VERSION}" > ${ROOT_DIR}/version/tag-number
  echo "Final release ${BOSH_RELEASE_VERSION} tagged via concourse" > ${ROOT_DIR}/version/annotate-msg

popd
