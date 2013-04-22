#!/bin/bash 

# Purpose : Create an Redhat based image that can be upload in Glance
# Author  : Thomas Oulevey <thomas.oulevey@cern.ch>
# Version : 20130422

# License :
# Copyright (c) 2013, Thomas Oulevey <thomas.oulevey@cern.ch>
# All rights reserved.
# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
#    Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
#    Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
#
#THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# Notes:
# - Need to be run on a yum capable machine.
# - Need to be root

usage()
{
cat << EOF
usage: $0 OPTIONS -u <url> <imagename>

This script create a small(-ish) el6-based image for Glance and can import it. 

OPTIONS:
   -a 		make image public in Glance
   -e		extras packages to install e.g: "ipmitool mypkg2 mypkg3" ;
   -g		execute glance command instead of printing it ;
   -h		print this help ;
   -n		nameserver ;
   -p		set root password / default: toor ;
   -s		image size. (number of block of 1024) / default: 2097152
   -u 		release rpm url or file ;
EOF
}

# Defaults
SIZE=2097152
PASSWORD="toor"
NAMESERVER=""
GLANCE_OPTS=""

# can be url or local rpm
EXTRAS_PKGS=""
optiong=false

while getopts “:hgu:n:e:p:s:” OPTION
do
        case $OPTION in
        h)
             usage
             exit 1
	     ;;
	a)
	     GLANCE_OPTS="$GLANCE_OPTS is_public=true"
	     ;;
	g)
             optiong=true
             ;;
	u)
	     RELEASE_RPM=$OPTARG
	     ;;
	n)
	     NAMESERVER=$OPTARG
	     ;;
	p)
	     PASSWORD=$OPTARG
	     ;;
	p)
	     EXTRAS_PKGS=$OPTARG
	     ;;
	s)
	     [[ $OPTARG =~ ^-?[0-9]+$ ]] && SIZE=$OPTARG
	     ;;
	?)
             exit 1
             ;;
        :)
             echo "Option -$OPTARG requires an argument."
             exit 1
             ;;
	esac
done

shift $(($OPTIND - 1))

if [ -z "$1" ]
then
	echo ""
	echo "[ERROR] You need to specify an image name"
	echo ""
        usage
	exit 1
fi

IMGNAME=$1

if [ `whoami` != "root"  ]; then
	echo "[ERROR] You need to run this script as the 'root' user not '`whoami`'"
	exit 1
fi

TMP=$PWD/$IMGNAME
rm -rf $TMP
mkdir -p $TMP
echo "Creating image with size:$SIZE"
dd if=/dev/zero of=$TMP/$IMGNAME.img bs=1024 count=$SIZE
mkfs.ext3 -F $TMP/$IMGNAME.img 

mkdir -p $TMP/loop
mount -o loop $TMP/$IMGNAME.img $TMP/loop
mkdir -p $TMP/loop/var/lib/rpm
rpm --rebuilddb --root=$TMP/loop
rpm -i --root=$TMP/loop --nodeps $RELEASE_RPM
yum --nogpgcheck --installroot=$TMP/loop install -y rpm-build yum initscripts kernel passwd dhclient openssh-clients openssh-server $EXTRAS_PKGS

cat >> $TMP/loop/etc/fstab << EOF
/dev/vda                /        ext3   defaults                                0       0
/dev/vdb                /mnt     auto   defaults,nobootwait,comment=cloudconfig 0       2
EOF

cat >> $TMP/loop/etc/sysconfig/network << EOF
NETWORKING=yes
HOSTNAME=vm-$IMGNAME
NOZEROCONF=yes
PEERDNS=no
PEERNTP=no
PEERNIS=no
EOF

cat >> $TMP/loop/etc/sysconfig/network-scripts/ifcfg-eth0 << EOF
DEVICE="eth0"
BOOTPROTO="dhcp"
IPV6INIT="yes"
MTU="1500"
NM_CONTROLLED="yes"
ONBOOT="yes"
TYPE="Ethernet"
EOF

if [[ -z $NAMESERVER ]]
then
	echo "Setting nameserver to $NAMESERVER..."
	echo "nameserver $NAMESERVER" >> $TMP/loop/etc/resolv.conf
fi

MOD_VER=$(ls $TMP/loop/lib/modules/)
echo "Changing root password..."
chroot $TMP/loop /bin/bash -c "echo $PASSWORD | /usr/bin/passwd --stdin root"
echo "Generating initramfs..." 
chroot $TMP/loop /bin/bash -c "mkinitrd --with virtio_pci --with virtio_ring --with virtio_blk --with virtio_net --with virtio_balloon --with virtio -f /boot/initramfs-$MOD_VER.img $MOD_VER"

cp $TMP/loop/boot/initramfs-* $TMP
cp $TMP/loop/boot/vmlinuz-* $TMP

umount $TMP/loop

if ( $optiong )
then
	cd $TMP/$IMGNAME
	KID=`glance add name="$IMGNAME-kernel" $GLANCE_OPTS container_format=aki disk_format=aki < ./vmlinuz*`	
	RID=`glance add name="$IMGNAME-ramdisk" $GLANCE_OPTS container_format=ari disk_format=ari < ./initramfs*.img`
	glance add name="$IMGNAME" $GLANCE_OPTS container_format=ami disk_format=ami kernel_id=${KID:25:100} ramdisk_id=${RID:25:100} <  ./$IMGNAME.img
	cd -

else
	echo """
	Need to execute on the glance host:

	cd $IMGNAME
 
	KID=\`glance add name="$IMGNAME-kernel" $GLANCE_OPTS container_format=aki disk_format=aki < ./vmlinuz*\`
	RID=\`glance add name="$IMGNAME-ramdisk" $GLANCE_OPTS container_format=ari disk_format=ari < ./initramfs*.img\`

	glance add name="$IMGNAME" $GLANCE_OPTS container_format=ami disk_format=ami kernel_id=\${KID:25:100} ramdisk_id=\${RID:25:100} < ./$IMGNAME.img

	"""
fi
