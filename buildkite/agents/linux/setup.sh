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

# Setup apt-get sources.
echo "deb https://apt.buildkite.com/buildkite-agent stable main" | sudo tee /etc/apt/sources.list.d/buildkite-agent.list
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 32A37959C2FA5C3C99EFBC32A79206696452D198
sudo apt-get update

# Install bazelisk (as bazel, as it does on macos)
wget https://github.com/bazelbuild/bazelisk/releases/download/v0.0.7/bazelisk-linux-amd64 
sudo install bazelisk-linux-amd64 /usr/local/bin/bazel
sudo chmod a+x /usr/local/bin/bazel

# Install the kotlinc tooling (not needed for bazel, but needed for kscript
sudo snap install kotlin

# Install kscript
wget https://github.com/holgerbrandl/kscript/releases/download/v2.8.0/kscript-2.8.0-bin.zip 
unzip kscript-2.8.0-bin.zip
sudo install kscript-2.8.0/bin/* /usr/local/bin/

sudo apt-get update && sudo apt-get install -y buildkite-agent
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

sudo systemctl enable buildkite-agent && sudo systemctl start buildkite-agent


