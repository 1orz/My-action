#!/bin/bash
sudo rm -rf /etc/apt/sources.list.d/*
sudo apt update -y
sudo apt install -y build-essential libncurses-dev gawk gettext clang llvm flex g++ gawk gcc-multilib \
    gettext git libncurses5-dev libssl-dev python3-distutils python3-pyelftools python3-setuptools \
    python3-dev python3-pip rsync unzip zlib1g-dev swig aria2 jq subversion qemu-utils ccache rename \
    libelf-dev device-tree-compiler libgnutls28-dev coccinelle libgmp3-dev libmpc-dev libfuse-dev
sudo apt purge -y azure-cli ghc* zulu* firefox powershell openjdk* dotnet* google* mysql* php* android*
sudo rm -rf /etc/apt/sources.list.d/* /usr/share/dotnet /usr/local/lib/android /opt/ghc
sudo apt autoremove
sudo apt clean