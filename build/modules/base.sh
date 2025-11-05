#!/bin/bash
# Author: Nihil Project
# Base package installation script

source common.sh

function package_base() {
    colorecho "Updating system and installing base packages"
    echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
    apt-get -y update && \
    apt-get -y install apt-utils dialog && \
    apt-get -y upgrade && \
    apt-get -y autoremove && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
    colorecho "Base packages installed"
}

