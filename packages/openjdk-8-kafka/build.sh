#!/usr/bin/env bash

set -e -x -u -o pipefail

major_ver=8
update_ver=202
build_number=01

# http://hg.openjdk.java.net/jdk8u/jdk8u/tags
# (note that tags on this page are not sorted)
tag=jdk${major_ver}u${update_ver}-b${build_number}

echo "----> Setting up dev env"
apt-get -y update
apt-get -y install openjdk-8-jdk mercurial build-essential zip \
  libx11-dev libxext-dev libxrender-dev libxtst-dev libxt-dev \
  libcups2-dev libfreetype6-dev libasound2-dev libelf-dev cpio

echo "----> Creating CA certs bundle"
mkdir -p cacerts/
awk '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/{ print $0; }' \
  /etc/ssl/certs/ca-certificates.crt | \
  csplit -n 3 -s -f cacerts/ - '/-----BEGIN CERTIFICATE-----/' {*}
rm cacerts/000
for I in $(find cacerts -type f | sort) ; do
  keytool -importcert -noprompt -keystore cacerts.jks \
    -storepass changeit -file $I -alias $(basename $I)
done

echo "----> Cloning OpenJDK 8 repo"
hg clone http://hg.openjdk.java.net/jdk8u/jdk8u
pushd jdk8u
  chmod +x common/bin/hgforest.sh configure get_source.sh
  ./get_source.sh
  ./common/bin/hgforest.sh checkout $tag
popd

echo "----> Configure freetype"
pushd jdk8u
  mkdir freetype && \
    ln -s /usr/include/freetype2 freetype/include && \
    ln -s /usr/lib/x86_64-linux-gnu/ freetype/lib
popd

echo "----> Building OpenJDK 8"
pushd jdk8u
  unset JAVA_HOME
  ./configure \
    --disable-debug-symbols \
    --disable-zip-debug-info \
    --with-boot-jdk=/usr/lib/jvm/java-8-openjdk-amd64/ \
    --enable-unlimited-crypto \
    --with-build-number=$build_number \
    --with-cacerts-file=$(pwd)/../cacerts.jks \
    --with-milestone=fcs \
    --with-freetype=./freetype \
    --with-update-version=$update_ver
  COMPANY_NAME="github.com/bosh-packages/java-release" make images
  chmod -R a+r build/linux-x86_64-normal-server-release/images
  tar czvf $(pwd)/../openjdk-jdk.tar.gz -C build/linux-x86_64-normal-server-release/images/j2sdk-image .
  tar czvf $(pwd)/../openjdk.tar.gz -C build/linux-x86_64-normal-server-release/images/j2re-image . \
    -C ../j2sdk-image ./lib/tools.jar ./bin/jcmd ./bin/jmap ./bin/jstack ./man/man1/jcmd.1 \
    ./man/man1/jmap.1 ./man/man1/jstack.1 -C ./jre ./lib/amd64/libattach.so
popd

echo "----> Export"
mkdir output/
mv openjdk-jdk.tar.gz output/${tag}-jdk.tar.gz
mv openjdk.tar.gz     output/${tag}.tar.gz
shasum -a 256 output/*.tar.gz > output/shasums
cat output/shasums
