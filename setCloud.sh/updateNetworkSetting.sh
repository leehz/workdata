#!/bin/sh
# Copyright 2012 Clustertech Limited. All rights reserved.
# Clustertech Cloud Management Platform.
#
# Author: Wenzhang zhu(wzzhu@clustertech.com)

# This script updates the system network configuration files.

. ./ccmp-net-conf.sh

if [ $# -eq 6 ]; then
  updateNetworkConfig $@
else
  >&2 echo "Invalid arguments (Need 6 arguments): $@"
  exit 1
fi
exit 0
