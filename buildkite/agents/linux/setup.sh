#!/bin/bash

echo "SETUP: START"

GH_RAW_URL=https://raw.githubusercontent.com
OS=linux
CFG_PROJECT_SLUG=cgruber/ci-configuration
CONFIG_URL=${GH_RAW_URL}/${CFG_PROJECT_SLUG}/master/buildkite/agents/${OS}

BK_CONFIG_DIR=/etc/buildkite-agent
BK_CONFIG_FILE=${BK_CONFIG_DIR}/buildkite-agent.cfg
BK_HOOKS_DIR=${BK_CONFIG_DIR}/hooks
BK_ENV_FILENAME=environment
BK_ENV=${BK_HOOKS_DIR}/${BK_ENV_FILENAME}

# Versions
BAZELISK_VERSION="1.3.0"
KSCRIPT_VERSION="2.9.3"
BUILDIFIER_VERSION="2.2.1"
KTLINT_VERSION="0.36.0"

function install_package() {
  echo "SETUP: Installing $@ debian package(s) using apt-get"
  sudo apt-get install -y $@
}

function install_binary() {
  url="$1"
  binary="$(basename ${url})"
  case $# in
    1)
      local_binary="${binary}"
      ;;
    2)
      local_binary="$2"
      ;;
    *)
      echo "Incorrect parameters."
      echo "Usage: install_binary <name> <version> <url> [<alias>]"
      exit 1
      ;;
  esac
  if (( $# == 4 )) ; then local_binary="$4" ; fi
  echo "SETUP: Installing ${binary} into /usr/local/bin/${local_binary} from ${url}"
  wget --progress=dot:giga ${url}
  sudo install ${binary} /usr/local/bin/${local_binary}
  sudo chmod a+x /usr/local/bin/${local_binary}
}

echo "SETUP: Setting up debian package sources"
# Setup apt-get sources.
echo "deb http://ftp.us.debian.org/debian sid main" | sudo tee /etc/apt/sources.list.d/openjdk8.list
echo "deb https://apt.buildkite.com/buildkite-agent stable main" | sudo tee /etc/apt/sources.list.d/buildkite.list
wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | sudo apt-key add -
echo "deb http://apt.llvm.org/xenial/ llvm-toolchain-xenial-6.0 main" | sudo tee /etc/apt/sources.list.d/clang.list
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 32A37959C2FA5C3C99EFBC32A79206696452D198
sudo apt-get update

# Because debian only has curl.
install_package wget

# Install bazelisk (as bazel, as it does on macos)
install_binary https://github.com/bazelbuild/bazelisk/releases/download/v${BAZELISK_VERSION}/bazelisk-linux-amd64 bazelisk
install_binary https://github.com/bazelbuild/buildtools/releases/download/${BUILDIFIER_VERSION}/buildifier
install_binary https://github.com/pinterest/ktlint/releases/download/${KTLINT_VERSION}/ktlint

install_package zip unzip

echo "SETUP: Installing kotlinc local toolchain"
# Install the kotlinc tooling (not needed for bazel, but needed for kscript)
sudo snap install kotlin --classic

echo "SETUP: Installing kscript ${KSCRIPT_VERSION}"
# Install kscript
wget https://github.com/holgerbrandl/kscript/releases/download/v${KSCRIPT_VERSION}/kscript-${KSCRIPT_VERSION}-bin.zip 
unzip kscript-${KSCRIPT_VERSION}-bin.zip
sudo install kscript-${KSCRIPT_VERSION}/bin/* /usr/local/bin/

install_package clang-6.0 clang
export CC=clang

install_package ca-certificates-java
install_package openjdk-8-jdk-headless
install_package openjdk-11-jdk-headless

echo "SETUP: Installing Buildkite Agent"
install_package buildkite-agent
sudo sed -i "s/xxx/${BUILDKITE_TOKEN}/g" ${BK_CONFIG_FILE}
cat >> ${BK_CONFIG_FILE} <<EOF
tags="os=linux,ci=true,queue=default"
EOF

echo "SETUP: Peparing Buildkite Environment"
# Set up the worker environment.
wget ${CONFIG_URL}/${BK_ENV_FILENAME}
sudo mv ${BK_ENV_FILENAME} ${BK_ENV}
sudo sed -i "s/__bazelisk_github_token__/${BAZELISK_GITHUB_TOKEN}/g" ${BK_ENV}

echo "SETUP: Starting Buildkite Agent"
sudo systemctl enable buildkite-agent && sudo systemctl start buildkite-agent

echo "SETUP: END"

