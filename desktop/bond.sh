#!/usr/bin/env bash
modprobe bonding && echo 6 > /sys/class/net/bond0/bonding/mode 
if [ $? != 0 ] ;
 then

	ifconfig br1 ||    brctl addbr br1 || echo "cannot create bridge: br1."; exit
    ifenslave bond0 eth0 eth1 eth2 &&  brctl addif br1 bond0 || echo "cannot ifenslave."; exit
hostname=`hostname`

if [ $HOSTNAMEx = CCMP1x ];
then
    ifconfig br1 10.0.1.1 up || echo "cannot config ip address";exit
else
    ifconfig br1 10.0.1.2 up || echo "cannot config ip address";exit
fi

else
    echo "cannot modprobe bonding or cannot change the work node."
    exit
fi

