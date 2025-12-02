#!/bin/bash
sudo rm -rf /usr/share/dotnet /usr/local/lib/android /opt/ghc
sudo apt update

sudo apt install libncurses-dev gawk gettext-base clang llvm flex g++ \
    git libssl-dev python3-setuptools \
    python3-dev python3-pip rsync unzip zlib1g-dev swig aria2 jq subversion qemu-utils rename \
    libelf-dev libgnutls28-dev coccinelle libgmp-dev libmpc-dev libfuse-dev neofetch

sudo apt autoremove
sudo apt clean