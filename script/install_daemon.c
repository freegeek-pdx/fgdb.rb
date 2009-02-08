#!/bin/sh

wget http://git.ryan52.info/redirect/daemon.c -O daemon.c
mkdir -p bin
gcc daemon.c -o bin/daemon
rm daemon.c
