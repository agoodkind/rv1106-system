#!/bin/bash

# Install dependencies for RV1106 firmware build

sudo apt-get update &&
    sudo apt-get install -y --no-install-recommends \
        build-essential \
        device-tree-compiler \
        gperf g++-multilib gcc-multilib \
        libnl-3-dev libdbus-1-dev libelf-dev libmpc-dev dwarves \
        bc openssl flex bison libssl-dev python3 python-is-python3 texinfo kmod cmake
