#!/bin/bash
# Author: Nihil Project
# Common utility functions for installation scripts

export RED='\033[1;31m'
export BLUE='\033[1;34m'
export GREEN='\033[1;32m'
export NOCOLOR='\033[0m'

function colorecho () {
    echo -e "${BLUE}[NIHIL] $*${NOCOLOR}"
}

function criticalecho () {
    echo -e "${RED}[NIHIL ERROR] $*${NOCOLOR}" 2>&1
    exit 1
}

function criticalecho-noexit () {
    echo -e "${RED}[NIHIL ERROR] $*${NOCOLOR}" 2>&1
}

