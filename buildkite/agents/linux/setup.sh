#!/bin/bash

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

# Setup apt-get sources.
echo "deb https://apt.buildkite.com/buildkite-agent stable main" | sudo tee /etc/apt/sources.list.d/buildkite-agent.list
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 32A37959C2FA5C3C99EFBC32A79206696452D198
sudo apt-get update

# Because debian only has curl.
sudo apt-get install wget

# Install bazelisk (as bazel, as it does on macos)
wget https://github.com/bazelbuild/bazelisk/releases/download/v${BAZELISK_VERSION}/bazelisk-linux-amd64 
sudo install bazelisk-linux-amd64 /usr/local/bin/bazel
sudo chmod a+x /usr/local/bin/bazel

wget https://github.com/bazelbuild/buildtools/releases/download/${BUILDIFIER_VERSION}/buildifier
sudo install buildifier /usr/local/bin/buildifier
sudo chmod a+x /usr/local/bin/buildifier

wget https://github.com/pinterest/ktlint/releases/download/${KTLINT_VERSION}/ktlint
sudo install ktlint /usr/local/bin/ktlint
sudo chmod a+x /usr/local/bin/ktlint

sudo apt-get install -y zip unzip

# Install the kotlinc tooling (not needed for bazel, but needed for kscript)
sudo snap install kotlin --classic

# Install kscript
wget https://github.com/holgerbrandl/kscript/releases/download/v${KSCRIPT_VERSION}/kscript-${KSCRIPT_VERSION}-bin.zip 
unzip kscript-${KSCRIPT_VERSION}-bin.zip
sudo install kscript-${KSCRIPT_VERSION}/bin/* /usr/local/bin/

sudo apt-get install -y buildkite-agent
sudo sed -i "s/xxx/${BUILDKITE_TOKEN}/g" ${BK_CONFIG_FILE}
cat >> ${BK_CONFIG_FILE} <<EOF
tags="os=linux,ci=true,queue=default"
EOF

# Set up the worker environment.
wget ${CONFIG_URL}/${BK_ENV_FILENAME}
sudo mv ${BK_ENV_FILENAME} ${BK_ENV}
sudo sed -i "s/__bazelisk_github_token__/${BAZELISK_GITHUB_TOKEN}/g" ${BK_ENV}

wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | sudo apt-key add -
sudo apt-add-repository "deb http://apt.llvm.org/xenial/ llvm-toolchain-xenial-6.0 main"
sudo apt-get install -y clang-6.0 clang
export CC=clang

sudo apt-get install -y openjdk-8-jdk-headless
sudo apt-get install -y openjdk-11-jdk-headless

sudo apt-get install -y build-essential

sudo systemctl enable buildkite-agent && sudo systemctl start buildkite-agent


