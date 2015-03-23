#!/bin/bash
# Copyright 2012 Clustertech Limited. All rights reserved.
# Clustertech Cloud Management Platform.
#
# Author: Dong LIN (dlin@clustertech.com)

# This script is used to install and config the cloud server from a CCMP
# installation CD.
# This script should be copied as the /ccmp/install.sh file of the CD.

clear
echo "##############################"
echo "      __ __  _   _  ___  "
echo "     / _/ _|| \_/ || o \\"
echo "    ( (( (_ | \_/ ||  _/"
echo "     \__\__||_| |_||_|  "
echo ""
echo "##############################"

# TODO(bobzhang): Verify the completeness of the installation media.
# For example, whether the needed files under the ccmp/dynamic folder are there.
# Do we lack some files?

RELATIVE_DIR_PATH_OF_THIS_SCRIPT=`dirname $0`
ABSOLUTE_DIR_PATH_OF_THIS_SCRIPT=`readlink -f $RELATIVE_DIR_PATH_OF_THIS_SCRIPT`
TMP_DISKS_FILE="/tmp/availableDisks.txt"

# Probes disks that could be used as CCMP installation destination.
# We exclude the instllation media (e.g., an external hard drive) as suggested
# in http://bug.clustertech.com/redmine/issues/10895.
# This function stores the qualified disks in the file TMP_DISKS_FILE each in
# one line.
function probeDisks() {
  installMediaMountPnt="/cdrom"
  rm -f $TMP_DISKS_FILE 2>/dev/null

  fdisk -l 2>/dev/null | grep "Disk /dev" | grep -v "/dev/mapper/" | \
    while read line; do
      disk=`echo $line | awk '{print $2}' | cut -d ":" -f1`
      if !(mount | grep -q "$disk[0-9]* .* $installMediaMountPnt" 2>/dev/null)
      then
        # Not the installation media, append it to $TMP_DISKS_FILE.
        echo "$line" >> $TMP_DISKS_FILE
      fi
    done

  echo "The following disk(s) has/have been detected:"
  # Another option is: grep -n ".*" $TMP_DISKS_FILE
  awk '{printf("  %s: ", NR); print}' $TMP_DISKS_FILE
}

# Executes a command with a timeout value.
# Params:
#   $1: timeout value in seconds
#   $2: command
# Returns 1 if timed out, 0 otherwise.
# Ref: http://unix.stackexchange.com/questions/43340/how-to-introduce-timeout-for-shell-scripting
function timeout() {
  time=$1

  # Start the command in a subshell to avoid problem with pipes
  # (spawn accepts one command)
  command="/bin/sh -c \"$2\""

  expect -c "set echo \"-noecho\"; set timeout $time; spawn -noecho $command; expect timeout { exit 1 } eof { exit 0 }"

  if [ $? = 1 ]; then
    echo "Fail to reboot in ${time} seconds, will switch to forcible reboot."
  fi
}

# The entry point of the script.
while true; do
  probeDisks

  diskNum=`cat $TMP_DISKS_FILE | wc -l`
  echo "Please type the number of the disk (e.g., 1) you want CCMP to be \
installed to followed by [ENTER]:"
  read diskIndex

  if test "$diskIndex" -ge 1 -a "$diskIndex" -le "$diskNum" 2>/dev/null; then
    # diskStr=`sed -n '$diskIndexp' $TMP_DISKS_FILE` is another option.
    diskStr=`awk "NR==$diskIndex{print; exit}" $TMP_DISKS_FILE`
    # diskStr example:
    # Disk /dev/sda: 320.1 GB, 320072933376 bytes
    DISK=`echo $diskStr | awk '{print $2}' | cut -d ":" -f1`
  else
    echo "Wrong disk number!"
    continue
  fi

  if [ ! -z $DISK ]; then
    if !(fdisk -l $DISK 2>/dev/null | grep -q $DISK); then
       echo "Hard disk '$DISK' does NOT exist."
    else
      echo "CCMP will be installed to '$DISK' and the data on it will be wiped \
out. Continue? (y/N)"
      read CONFIRM
      if [ ! -z $CONFIRM ]; then
        if [ "$CONFIRM" = "y" -o "$CONFIRM" = "Y" ]; then
          break
        fi
      fi
    fi
  fi
done

PART1=$(printf "%s1" $DISK)
PART2=$(printf "%s2" $DISK)

echo "Installing CCMP to the hard disk (i.e., $DISK) ..."
echo "It'll take several minutes. Please wait."
# dd the base Ubuntu system.
gunzip -dc $ABSOLUTE_DIR_PATH_OF_THIS_SCRIPT/ccmp.gz | pv | dd of=$DISK bs=1M
sync
echo "Resizing partition..."
parted -s $DISK rm 1
parted -s $DISK unit s mkpart primary ext4 2048 80%
parted -s $DISK unit s mkpart primary ext4 80% 100%

# Tell the Linux kernel about the presence and numbering of on-disk partitions
# so that the modification to the partition table has taken effect before going
# ahead to call e2fsck. Another option is using "partprobe $DISK", which informs
# the OS of partition table changes.
partx -a $DISK 2>/dev/null

# Sleep for a while to ensure that the new partition table has taken effect.
sleep 20

echo "Checking partition 1..."
e2fsck -pf $PART1
echo "Resizing partition 1..."
resize2fs $PART1
echo "Checking partition 1..."
e2fsck -pf $PART1

# Copy other files.
DYNAMIC_FOLDER_PATH="$ABSOLUTE_DIR_PATH_OF_THIS_SCRIPT/dynamic"
CCMP_MOUNT_POINT=/tmp/ccmp
mkdir -p $CCMP_MOUNT_POINT
mount $PART1 $CCMP_MOUNT_POINT

# Copy ccmp-cloud ccmp-admin-httpd, and ccmp-httpd binaries.
mkdir -p $CCMP_MOUNT_POINT/home/ccmp/ccmp_bins/
echo "Copying ccmp-cloud binary..."
cp $DYNAMIC_FOLDER_PATH/ccmpBinaries/ccmp-cloud \
   $CCMP_MOUNT_POINT/home/ccmp/ccmp_bins/
chmod a+x $CCMP_MOUNT_POINT/home/ccmp/ccmp_bins/ccmp-cloud
echo "Copying ccmp-httpd and ccmp-admin-httpd binary..."
cp $DYNAMIC_FOLDER_PATH/ccmpBinaries/ccmp-*httpd \
   $CCMP_MOUNT_POINT/home/ccmp/ccmp_bins/
chmod a+x $CCMP_MOUNT_POINT/home/ccmp/ccmp_bins/ccmp-*httpd

# Copy certificates for CCMP cloud and httpd.
mkdir -p $CCMP_MOUNT_POINT/home/ccmp/ccmp_bins/etc/production/
echo "Copying certificates for CCMP cloud..."
cp $DYNAMIC_FOLDER_PATH/cert/cloud_crt.pem \
   $CCMP_MOUNT_POINT/home/ccmp/ccmp_bins/etc/production/
cp $DYNAMIC_FOLDER_PATH/cert/cloud_key.pem \
   $CCMP_MOUNT_POINT/home/ccmp/ccmp_bins/etc/production/
echo "Copying certificates for CCMP httpd..."
cp $DYNAMIC_FOLDER_PATH/cert/httpd_crt.pem \
   $CCMP_MOUNT_POINT/home/ccmp/ccmp_bins/etc/production/
cp $DYNAMIC_FOLDER_PATH/cert/httpd_key.pem \
   $CCMP_MOUNT_POINT/home/ccmp/ccmp_bins/etc/production/

# Copy email templates.
mkdir -p $CCMP_MOUNT_POINT/home/ccmp/ccmp_bins/etc/templates/
echo "Copying email templates..."
cp -a $DYNAMIC_FOLDER_PATH/etc/templates/email/ \
      $CCMP_MOUNT_POINT/home/ccmp/ccmp_bins/etc/templates/

# Copy language files.
echo "Copying language files..."
cp -a $DYNAMIC_FOLDER_PATH/etc/lang/ \
      $CCMP_MOUNT_POINT/home/ccmp/ccmp_bins/etc/

# Copy dnsmasq config files.
echo "Copying dnsmasq config files..."
cp -a $DYNAMIC_FOLDER_PATH/etc/dnsmasq/ \
      $CCMP_MOUNT_POINT/home/ccmp/ccmp_bins/etc/

# Copy frontend files.
echo "Copying frontend files..."
cp -a $DYNAMIC_FOLDER_PATH/etc/frontend/ \
      $CCMP_MOUNT_POINT/home/ccmp/ccmp_bins/etc/

# Copy ccmp.conf file for cloud server.
echo "Copying ccmp.conf file for CCMP cloud..."
cp $DYNAMIC_FOLDER_PATH/etc/ccmpConf/ccmp.conf \
   $CCMP_MOUNT_POINT/home/ccmp/ccmp_bins/etc/
# ccmp.conf is a security sensitive file as MySQL root password is stored in it.
chmod 600 $CCMP_MOUNT_POINT/home/ccmp/ccmp_bins/etc/ccmp.conf

# Copy drbd_global_common.conf.tpl as /etc/drbd.d/global_common.conf in cloud
# server.
cp $DYNAMIC_FOLDER_PATH/HA/drbd_global_common.conf.tpl \
   $CCMP_MOUNT_POINT/etc/drbd.d/global_common.conf

# Copy keepalived.conf.tpl as /etc/keepalived/keepalived.conf in cloud server.
cp $DYNAMIC_FOLDER_PATH/HA/keepalived.conf.tpl \
   $CCMP_MOUNT_POINT/etc/keepalived/keepalived.conf

# Copy cloud server HA related scripts to the path /root/HA/ in cloud server.
mkdir -p $CCMP_MOUNT_POINT/root/HA/
cp $DYNAMIC_FOLDER_PATH/HA/*.sh $CCMP_MOUNT_POINT/root/HA/
# Replace the placeholder "{{.CCMP_HA_MYSQL_DISK_REPLACE_DURING_INSTALLATION}}"
# in /root/HA/ccmp-ha-conf.sh with the real partition path (e.g., /dev/sda2).
sed -i "s#{{.CCMP_HA_MYSQL_DISK_REPLACE_DURING_INSTALLATION}}#$PART2#g" \
  $CCMP_MOUNT_POINT/root/HA/ccmp-ha-conf.sh

# Copy golden images.
mkdir -p $CCMP_MOUNT_POINT/home/goldenImages/
echo "Copying golden images..."
cp $DYNAMIC_FOLDER_PATH/goldenImages/iso/* $CCMP_MOUNT_POINT/home/goldenImages/
cp $DYNAMIC_FOLDER_PATH/goldenImages/qcow2/* \
   $CCMP_MOUNT_POINT/home/goldenImages/

mkdir -p $CCMP_MOUNT_POINT/home/tftpboot/casper/
# Copy resource node rootfs.sfs, rootfs.tar.gz and rc.local.
echo "Copying rootfs.sfs, rootfs.tar.gz and rc.local ..."
cp $DYNAMIC_FOLDER_PATH/resourceCasper/rootfs.sfs \
   $CCMP_MOUNT_POINT/home/tftpboot/casper/
cp $DYNAMIC_FOLDER_PATH/resourceCasper/rootfs.tar.gz \
   $CCMP_MOUNT_POINT/home/tftpboot/casper/
cp $DYNAMIC_FOLDER_PATH/resourceCasper/rc.local\
   $CCMP_MOUNT_POINT/home/tftpboot/casper/
chmod a+r $CCMP_MOUNT_POINT/home/tftpboot/casper/rootfs.sfs
chmod a+r $CCMP_MOUNT_POINT/home/tftpboot/casper/rootfs.tar.gz
chmod a+r $CCMP_MOUNT_POINT/home/tftpboot/casper/rc.local

mkdir -p $CCMP_MOUNT_POINT/home/tftpboot/casper/
# Copy resource node initrd.ubuntu.
echo "Copying initrd.ubuntu..."
cp $DYNAMIC_FOLDER_PATH/resourceInitrd/initrd.ubuntu \
   $CCMP_MOUNT_POINT/home/tftpboot/casper/
chmod a+rx $CCMP_MOUNT_POINT/home/tftpboot/casper/initrd.ubuntu

# Copy resource node initrd.centos.
echo "Copying initrd.centos..."
cp $DYNAMIC_FOLDER_PATH/resourceInitrd/initrd.centos \
   $CCMP_MOUNT_POINT/home/tftpboot/casper/
chmod a+rx $CCMP_MOUNT_POINT/home/tftpboot/casper/initrd.centos

# Copy resource node linux kernels.
echo "Copying vmlinuz files..."
cp $DYNAMIC_FOLDER_PATH/resourceKernels/vmlinuz.centos \
   $CCMP_MOUNT_POINT/home/tftpboot/casper/
cp $DYNAMIC_FOLDER_PATH/resourceKernels/vmlinuz.ubuntu \
   $CCMP_MOUNT_POINT/home/tftpboot/casper/
chmod a+rx $CCMP_MOUNT_POINT/home/tftpboot/casper/vmlinuz.centos
chmod a+rx $CCMP_MOUNT_POINT/home/tftpboot/casper/vmlinuz.ubuntu

# Copy pxelinux.cfg for tftpboot.
mkdir -p $CCMP_MOUNT_POINT/home/tftpboot/pxelinux.cfg/
echo "Copying pxelinux.cfg..."
cp $DYNAMIC_FOLDER_PATH/pxelinux.cfg/pxelinux.cfg \
   $CCMP_MOUNT_POINT/home/tftpboot/pxelinux.cfg/default

# Generate ccmp.tar using files under the $DYNAMIC_FOLDER_PATH folder.
echo "Generating and copying ccmp.tar..."
cd $CCMP_MOUNT_POINT/home/tftpboot/
tar xvfp ccmp.tar
CCMP_BINARIES_FOLDER="ccmp_binaries"
cp $DYNAMIC_FOLDER_PATH/ccmpBinaries/ccmp-backend $CCMP_BINARIES_FOLDER
chmod a+x $CCMP_BINARIES_FOLDER/ccmp-backend
mkdir -p $CCMP_BINARIES_FOLDER/etc/production/
mkdir -p $CCMP_BINARIES_FOLDER/etc/templates/
cp $DYNAMIC_FOLDER_PATH/etc/ccmpConf/ccmp.conf $CCMP_BINARIES_FOLDER/etc/
cp $DYNAMIC_FOLDER_PATH/cert/backend_crt.pem \
   $CCMP_BINARIES_FOLDER/etc/production/
cp $DYNAMIC_FOLDER_PATH/cert/backend_key.pem \
   $CCMP_BINARIES_FOLDER/etc/production/
cp -a $DYNAMIC_FOLDER_PATH/etc/templates/kvm/ \
   $CCMP_BINARIES_FOLDER/etc/templates/
tar cvf ccmp.tar $CCMP_BINARIES_FOLDER/*
rm -rf $CCMP_BINARIES_FOLDER
cd -

# Copy mysql.sql file.
echo "Copying mysql.sql..."
cp $DYNAMIC_FOLDER_PATH/mysql.sql/mysql.sql $CCMP_MOUNT_POINT/root/

# Copy network interfaces.
mkdir -p $CCMP_MOUNT_POINT/etc/network/
echo "Copying network interfaces..."
cp $DYNAMIC_FOLDER_PATH/cloudServerInterfaces/cloudServerInterfacesStatic \
   $CCMP_MOUNT_POINT/etc/network/interfaces

# Copy etc/exports file.
echo "Copying etc/exports file..."
cp $DYNAMIC_FOLDER_PATH/etcExports/export.cfg $CCMP_MOUNT_POINT/etc/exports

# Copy etc/sysctl.conf file.
echo "Copying etc/sysctl.conf file..."
cp $DYNAMIC_FOLDER_PATH/sysctl.conf/sysctl.conf \
   $CCMP_MOUNT_POINT/etc/sysctl.conf

# Copy root/ccmp.sh file.
echo "Copying root/ccmp.sh file..."
cp $DYNAMIC_FOLDER_PATH/cloudServerStartup/cloudServerStartup \
   $CCMP_MOUNT_POINT/root/ccmp.sh
chmod a+x $CCMP_MOUNT_POINT/root/ccmp.sh

# Copy home/ccmp/script script files.
mkdir -p $CCMP_MOUNT_POINT/home/ccmp/script
echo "Copying home/ccmp/script/*.sh ..."
cp $DYNAMIC_FOLDER_PATH/setCloud.sh/*.sh $CCMP_MOUNT_POINT/home/ccmp/script
# Make these script files visible only to root for safety considerations.
chmod 600 $CCMP_MOUNT_POINT/home/ccmp/script/*.sh
chmod u+x $CCMP_MOUNT_POINT/home/ccmp/script/ccmp-net-conf.sh

sync
sleep 5
umount $CCMP_MOUNT_POINT

echo "Finished all configurations. The system will reboot in 5 seconds to complete the installation."

for n in {5..1}; do
  printf "\r%s " $n
  sleep 1
done

# Originally, a simple "reboot" command was used here. However, later testings
# found that sometimes we get stuck here. To fix this problem, we switch to
# using "echo 1 > /proc/sys/kernel/sysrq" and "echo b > /proc/sysrq-trigger" to
# achieve a forcible reboot here if the "reboot" command gets stuck.
# As this approach does not attempt to sync filesystems, to ensure that all
# content in the file system buffers gets flushed to disk, we first call
# the "sync" command before trying the forcible reboot.
# Ref: http://www.linuxjournal.com/content/rebooting-magic-way
echo "Rebooting..."
timeout 10 "reboot"

for i in {1..10}
do
  sync
done

echo 1 > /proc/sys/kernel/sysrq
echo b > /proc/sysrq-trigger
