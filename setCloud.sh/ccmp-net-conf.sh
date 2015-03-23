#!/bin/sh
# Copyright 2014 Clustertech Limited. All rights reserved.
# Clustertech Cloud Management Platform.
#
# Author: Wenzhang Zhu(wzzhu@clustertech.com)

# This file includes the shared network utility functions for CCMP configuration

# The function updates the network configuration
# The input arguments are
#   $1 -- The IP address for Internet
#   $2 -- The subnet mask for Internet
#   $3 -- The gateway IP address for Internet
#   $4 -- The DNS server IP for Internet
#   $5 -- The domain name of the cloud server
#   $6 -- The intranet IP prefix.
#         (No trailing '.', e.g., "172.16" instead of "172.16.".)
updateNetworkConfig() {
  ETH1_IP=$1
  ETH1_MASK=$2
  ETH1_GW=$3
  ETH1_DNS=$4
  DOMAIN_NAME=$5
  ETH0_IP_PREFIX=$6
  sed -i -e "s/\(nfsroot=\).*\(\/home\/nfs\)/\1$ETH0_IP_PREFIX.0.254:\2/g" \
    /home/tftpboot/pxelinux.cfg/default
  sed -i -e "s/\(CCMP_DNS_SERVER_IP=\).*$/\1$ETH1_DNS/g" /root/ccmp.sh
  sed -i -e "s/\(\/home\/nfs\).*\(.0.0\)/\1 $ETH0_IP_PREFIX\2/g" /etc/exports
  sed -i -e "s/\(host = \).*\(.0.254\)/\1 $ETH0_IP_PREFIX\2/g" \
    /home/ccmp/ccmp_bins/etc/ccmp.conf
  sed -i -e \
    "s/\(bcast_addr=\)[0-9]*.[0-9]*./\1$ETH0_IP_PREFIX./g;\
     s/\(default_gateway=\)[0-9]*.[0-9]*./\1$ETH0_IP_PREFIX./g;\
     s/\(dns_server=\)[0-9]*.[0-9]*./\1$ETH0_IP_PREFIX./g;\
     s/\(domain_name=\).*/\1$DOMAIN_NAME/g;\
     s/\(server_network=\)[0-9]*.[0-9]*./\1$ETH0_IP_PREFIX./g;\
     s/\(next_server=\)[0-9]*.[0-9]*./\1$ETH0_IP_PREFIX./g;\
     s/\(ccmp_dhcpd_ip_range_first=\)[0-9]*.[0-9]*./\1$ETH0_IP_PREFIX./g;\
     s/\(ccmp_dhcpd_ip_range_last=\)[0-9]*.[0-9]*./\1$ETH0_IP_PREFIX./g;\
     s/\(native_dhcpd_ip_range_first=\)[0-9]*.[0-9]*./\1$ETH0_IP_PREFIX./g;\
     s/\(native_dhcpd_ip_range_last=\)[0-9]*.[0-9]*./\1$ETH0_IP_PREFIX./g" \
       /home/ccmp/ccmp_bins/etc/dnsmasq/subnets.conf
  sed -i -e \
     "/iface br0/,/broadcast/s/\(address\).*$/\1 $ETH0_IP_PREFIX.0.254/g;\
      /iface br0/,/broadcast/s/\(network\).*$/\1 $ETH0_IP_PREFIX.0.0/g;\
      /iface br0/,/broadcast/s/\(broadcast\).*$/\1 $ETH0_IP_PREFIX.0.255/g;\
      /^[ ]*auto eth1/d;\
      /^[ ]*iface eth1/,/^[ ]*auto br0/d;\
      /^[ ]*iface br0/i\
auto eth1\n\
iface eth1 inet static\n\
    address $ETH1_IP\n\
    netmask $ETH1_MASK\n\
    gateway $ETH1_GW\n\
    dns-nameservers $ETH1_DNS\n\n\
auto br0\n" /etc/network/interfaces
}

# Ask for the network settings for CCMP.
# The network setting values are kept in shared shell variables:
# ETH1_IP, ETH1_MASK, ETH1_GW, ETH1_DNS, DOMAIN_NAME, ETH0_IP_PREFIX.
# Return 0 if user confirms the input, otherwise, 1.
askForInputs() {
  echo "Please enter the \033[31mIP address\033[0m (e.g., 192.168.0.1) \
used for internet followed by [ENTER]:"
  read ETH1_IP
  echo "Please enter the \033[31msubnet mask\033[0m for $ETH1_IP \
(e.g., 255.255.255.0) followed by [ENTER]:"
  read ETH1_MASK
  echo "Please enter the \033[31mdefault gateway\033[0m for \
$ETH1_IP/$ETH1_MASK (e.g., 192.168.0.254) followed by [ENTER]:"
  read ETH1_GW
  echo "Please enter the \033[31mDNS server IP\033[0m \
(e.g., 8.8.8.8) followed by [ENTER]:"
  read ETH1_DNS
  echo "Please enter the \033[31mDomain name of the cloud server\033[0m \
(e.g., clustertech.com) followed by [ENTER]:"
  read DOMAIN_NAME
  echo "Please enter the \033[31mintranet IP prefix\033[0m \
used by CCMP (No trailing '.', e.g., 172.16 or 10.1 or 192.168, \
but NOT '192.168.') followed by [ENTER]:"
  read ETH0_IP_PREFIX
  echo
  echo "The network configurations are:"
  echo
  echo "Internet $ETH1_IP/$ETH1_MASK"
  echo "Gateway $ETH1_GW"
  echo "Nameserver $ETH1_DNS"
  echo "Domain $DOMAIN_NAME"
  echo "Intranet $ETH0_IP_PREFIX.0.0/255.255.0.0"
  echo
  echo "Are the inputs correct? (y/N)"
  read confirm
  if [ ! -z $confirm ]; then
    if [ $confirm = "y" -o $confirm = "Y" ]; then
      return 0
    fi
  fi
  return 1
}
