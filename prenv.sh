#!/bin/bash
sudo rm -rf /etc/apt/sources.list.d/*
sudo apt update
sudo apt install -y build-essential libncurses-dev gawk gettext clang
sudo apt autoremove --purge
sudo ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
sudo -E apt-get -qq update
sudo -E apt-get -qq install build-essential clang llvm flex g++ gawk gcc-multilib gettext \
    git libncurses5-dev libssl-dev python3-distutils python3-pyelftools python3-setuptools \
    python3-dev python3-pip rsync unzip zlib1g-dev swig aria2 jq subversion qemu-utils ccache rename \
    libelf-dev device-tree-compiler libgnutls28-dev coccinelle libgmp3-dev libmpc-dev libfuse-dev gcc-multilib
pip3 install --user -U pylibfdt
sudo -E apt-get -qq purge azure-cli ghc* zulu* firefox powershell openjdk* dotnet* google* mysql* php* android*
sudo rm -rf /etc/apt/sources.list.d/* /usr/share/dotnet /usr/local/lib/android /opt/ghc
sudo -E apt-get -qq autoremove --purge
sudo -E apt-get -qq clean
sudo df -h
