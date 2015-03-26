#! /bin/bash
function debuglog()
{
	echo "$1" >>/tmp/log
}

gluster='172.16.0.244:/ccmp_vol'
debuglog "starting"
MOUNTPOINT='/mnt/ccmpvolume'
if [ ! -d $MOUNTPOINT ]
then
	mkdir $MOUNTPOINT
fi
#service lxc-net stop
ifgfsmounted=$(mount|grep glusterfs)
debuglog $(ifgfsmounted)
if [ xx"$ifgfsmounted" == "xx" ]
then
	debuglog "mounting gfs"
	busybox sleep 3 && mount.glusterfs "$gluster" "$MOUNTPOINT" >>/tmp/log 2>&1
	busybox sleep 3
	if [ $? == 0 ]
	then
		debuglog "mounted $MOUNTPOINT"
	else
		debuglog "mounting failed"
	fi
	wait
else
	MOUNTPOINT=$(mount|grep nfs|awk '{print $3}')
	debuglog "mounted $MOUNTPOINT"
fi
EMPOINT=${MOUNTPOINT}/em

mkdir /home/lxc
cd /home/lxc

mkdir rw
mkdir ro
mkdir rootfs
mount -t tmpfs none rw
mount -o loop ${EMPOINT}/em.root.fs ro
mount -t overlayfs -o lowerdir=ro,upperdir=rw none rootfs

# sed -i '/BOOTPROTO/s/dhcp/none/' rootfs/etc/sysconfig/network-scripts/ifcfg-eth0
# echo -e "NETWORKING=yes\nHOSTNAME=n3" > rootfs/etc/sysconfig/network
# echo -e "127.0.0.1 localhost\n172.16.1.3 n3" > rootfs/etc/hosts
echo -e "IPADDR=172.16.1.102\nNETMASK=255.255.255.0\n" >> rootfs/etc/sysconfig/network-scripts/ifcfg-eth0
echo -e "NETWORKING=yes\nHOSTNAME=n2" > rootfs/etc/sysconfig/network
echo -e "127.0.0.1 localhost\n172.16.1.101 n1\n172.16.1.102 n2\n" > rootfs/etc/hosts

# cp $MNT/hosts rootfs/etc/hosts
# cp $MNT/em.lic rootfs/usr/clustertech/common/license/em.lic
# cp $MNT/ssh_config rootfs/etc/ssh/
cp ${EMPOINT}/config config
lxc-create -n lxc -f config
lxc-start -d -n lxc
debuglog "wait start"
wait
debuglog "wait finished"
#run script
lxc-attach -n lxc /mnt/em/run
debuglog "run finished"
