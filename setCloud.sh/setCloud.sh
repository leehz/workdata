#!/bin/sh
# Copyright 2012 Clustertech Limited. All rights reserved.
# Clustertech Cloud Management Platform.
#
# Author: bobzhang (bobzhang@clustertech.com)

# This script takes user inputs and resets the CCMP cloud along with its network
# configurations.
#
# The script can be run in interactive mode without any argument.
# If the argument "-b" (for batch) is specified, it will need 5 more arguments
# to be supplied. They are:
#   The IP address for Internet
#   The subnet mask for Internet
#   The gateway IP address for Internet
#   The DNS server IP for Internet
#   The domain name of current cloud server
#   The intranet IP prefix (Note no trailing '.', e.g.,
#   "172.16" instead of "172.16.")
#
# e.g.,
# setCloud.sh -b 192.168.0.1 255.255.255.0 192.168.0.254 8.8.8.8 \
#             clustertech.com 172.16

# Import the shared utility script
. ./ccmp-net-conf.sh

resetDb() {
  user=$1
  password=$2
  mysql -u $user -p$password -e "drop database ccmp;"
  mysql -u $user -p$password -e "drop database ccmpPerf;"
  # Using /root/sql.bak to solve http://bug.clustertech.com/redmine/issues/11342
  mysql -u $user -p$password < /root/sql.bak
}

if [ $# -eq 7 -a "$1" = "-b" ]; then
  killall ccmp-cloud ccmp-httpd dnsmasq 2>&1
  resetDb
  updateNetworkConfig $2 $3 $4 $5 $6 $7
  exit 0
fi

# The user/password for CCMP's mysql database
mysql_user=`grep -rn "mysql_user" /home/ccmp/ccmp_bins/etc/ccmp.conf | head -1 | awk '{print $3}'`
mysql_password=`grep -rn "mysql_password" /home/ccmp/ccmp_bins/etc/ccmp.conf | head -1 | awk '{print $3}'`

clear
echo "##############################"
echo "      __ __  _   _  ___  "
echo "     / _/ _|| \_/ || o \\"
echo "    ( (( (_ | \_/ ||  _/"
echo "     \__\__||_| |_||_|  "
echo ""
echo "##############################"

echo "Please \033[32mpower off\033[0m all resource nodes in advcance."
echo "This script will reset the configurations of entire CCMP cloud."
echo "Your configurations, VMs, images will be \033[31mwiped \
out\033[0m completely."

while true
do
  echo
  echo "Continue? (y/N) \033[32mCTRL+C to abort at any time\033[0m"
  read CONFIRM
  if [ -z $CONFIRM ]; then
    break
  fi
  if [ $CONFIRM = "n" -o $CONFIRM = "N" ]; then
    break
  fi
  if askForInputs; then
    echo "Stopping CCMP binaries ..."
    killall ccmp-cloud ccmp-httpd dnsmasq 2>&1
    echo "Wiping out all data in databases ..."
    resetDb $mysql_user $mysql_password
    echo "Restoring network configurations ..."
    updateNetworkConfig $ETH1_IP $ETH1_MASK $ETH1_GW $ETH1_DNS \
                        $DOMAIN_NAME $ETH0_IP_PREFIX
    echo "The machine needs to reboot for the settings to take effect."
    echo "Do you want to reboot now? (y/N)"
    read rb
    if [ "$rb" = "y" -o "$rb" = "Y" ]; then
      reboot
    fi
    exit 0
  fi
done
