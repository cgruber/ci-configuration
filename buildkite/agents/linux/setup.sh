#!/bin/bash

echo "deb https://apt.buildkite.com/buildkite-agent stable main" | sudo tee /etc/apt/sources.list.d/buildkite-agent.list
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 32A37959C2FA5C3C99EFBC32A79206696452D198

wget https://github.com/bazelbuild/bazelisk/releases/download/v0.0.7/bazelisk-linux-amd64 
sudo mv bazelisk-linux-amd64 /usr/local/bin/bazel
sudo chmod a+x /usr/local/bin/bazel

sudo apt-get update && sudo apt-get install -y buildkite-agent
sudo sed -i "s/xxx/${BUILDKITE_TOKEN}/g" /etc/buildkite-agent/buildkite-agent.cfg
cat >> /etc/buildkite-agent/buildkite-agent.cfg <<EOF
tags="os=linux,ci=true,queue=default"
EOF
sudo systemctl enable buildkite-agent && sudo systemctl start buildkite-agent
