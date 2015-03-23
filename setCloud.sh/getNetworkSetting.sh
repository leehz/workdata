#!/bin/sh
# Copyright 2014 Clustertech Limited. All rights reserved.
# Clustertech Cloud Management Platform.
#
# Author: Wenzhang Zhu(wzzhu@clustertech.com)

# The script extracts the network settings from various configuration files.
# It is expected the output should contain 6 definitions used in setCloud.sh.
# The value for ETH0_IP_PREFIX should be the same from all places extracted.
# The output is in json format as shown below.
#
# {
#   "ETH0_IP_PREFIX": "172.16",
#   "ETH1_DNS": "192.168.128.37",
#   "ETH1_DOMAIN": "clustertech.com",
#   "ETH1_GATEWAY": "10.10.0.254",
#   "ETH1_IP": "10.10.0.69",
#   "ETH1_NETMASK": "255.255.255.0"
# }
#
# If there are problems in those configuration files, the json object will
# use "*" to indicate an inconsistent value. e.g.,
# {
#   "ETH0_IP_PREFIX": "*",
#   ...
# }
# If some fields are missing, they will not be shown in json object.

TMP_OUTPUT=/tmp/network-$$.txt
grep "nfsroot" /home/tftpboot/pxelinux.cfg/default |\
sed -e "s/^.*nfsroot[ ]*=[ ]*\([0-9\.]*\)\.0\.254.*/ETH0_IP_PREFIX=\1/g" \
    >$TMP_OUTPUT

grep "CCMP_DNS_SERVER_IP=" /root/ccmp.sh >>$TMP_OUTPUT

grep "/home/nfs" /etc/exports |\
sed -e "s/^\/home\/nfs[ ]*\([0-9\.]*\)\.0\.0\/24.*/ETH0_IP_PREFIX=\1/" \
    >> $TMP_OUTPUT

awk 'BEGIN{start = 0;} \
     /\[Cloud server\]/ {start = 1;} \
     /^host[ ]*=/ {if (start) {print $0; start = 0;};}' \
    </home/ccmp/ccmp_bins/etc/ccmp.conf |\
sed -e 's/host[ ]*=[ ]*\([0-9\.]*\)\.0\.254/ETH0_IP_PREFIX=\1/' >> $TMP_OUTPUT

for name in bcast_addr default_gateway dns_server domain_name server_network \
            next_server ccmp_dhcpd_ip_range_first ccmp_dhcpd_ip_range_last \
            native_dhcpd_ip_range_first native_hdcpd_ip_range_last
do
  grep "$name" /home/ccmp/ccmp_bins/etc/dnsmasq/subnets.conf |\
  sed -e "s/$name=\([0-9]*\.[0-9]*\)\..*/$name=\1/g"|uniq >> $TMP_OUTPUT
done

cat /etc/network/interfaces |\
awk '/iface br0/ {start = 1;} \
     /address/ {if (start > 0 && start < 4) {print $2; start++;}} \
     /network/ {if (start > 0 && start < 4) {print $2; start++;}} \
     /broadcast/ {if (start > 0 && start < 4) {print $2; start++;}}' |\
sed -e "s/[ ]*\([0-9]*\.[0-9]*\).*/\1/"|uniq|\
xargs printf "ETH0_IP_PREFIX=%s\n" >> $TMP_OUTPUT

cat /etc/network/interfaces |\
awk '/iface eth1/ {start = 1;} \
     /address/ {if (start > 0 && start < 5) {\
                  printf("ETH1_IP=%s\n", $2); start++;}}\
     /netmask/ {if (start > 0 && start < 5) {\
                  printf("ETH1_NETMASK=%s\n", $2); start++;}} \
     /gateway/ {if (start > 0 && start < 5) {\
                  printf("ETH1_GATEWAY=%s\n",$2); start++;}} \
     /dns-nameservers/ {if (start > 0 && start < 5) {\
                  printf("ETH1_DNS=%s\n", $2); start++;}}'\
    >> $TMP_OUTPUT

# Change the output to json format
# Make sure that it only contains exactly 6 unique lines we want.
cat $TMP_OUTPUT |\
  sed -e "s/bcast_addr/ETH0_IP_PREFIX/g; \
          s/default_gateway/ETH0_IP_PREFIX/g; \
          s/dns_server/ETH0_IP_PREFIX/g; \
          s/domain_name/ETH1_DOMAIN/g; \
          s/server_network/ETH0_IP_PREFIX/g; \
          s/next_server/ETH0_IP_PREFIX/g; \
          s/ccmp_dhcpd_ip_range_first/ETH0_IP_PREFIX/g; \
          s/ccmp_dhcpd_ip_range_last/ETH0_IP_PREFIX/g; \
          s/native_dhcpd_ip_range_first/ETH0_IP_PREFIX/g; \
          s/native_dhcpd_ip_range_last/ETH0_IP_PREFIX/g;" |\
  sort -u | grep "^[A-Z_][A-Z_0-9]*=.*" |\
  awk 'BEGIN {FS="="} \
       /ETH1_DOMAIN|ETH0_IP_PREFIX|ETH1_DNS|ETH1_GATEWAY|ETH1_IP|\
ETH1_NETMASK/ { if (map[$1] != "") {\
                                map[$1]="*";\
                              } else {\
                                map[$1] = $2;\
                              }\
                            }\
       END { for (key in map) {\
               printf("  \"%s\": \"%s\",\n", key, map[key]);
           }\
  }' |\
  sed -e "$ s/,$//" |\
  sed -e "1 i\
  {" |\
  sed -e "$ a\
  }"

rm $TMP_OUTPUT
