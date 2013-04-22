openstack-tools
===============

Tools and doc arround Openstack with el6 based distro.

* create-glance-image-el6.sh

USAGE:
=======

usage: create-glance-image-el6.sh OPTIONS -u <url> <imagename>

This script create a small(-ish) el6-based image for Glance and can import it. 

OPTIONS:
   -a           make image public in Glance
   -e           extras packages to install e.g: "ipmitool mypkg2 mypkg3" ;
   -g           execute glance command instead of printing it ;
   -h           print this help ;
   -n           nameserver ;
   -p           set root password / default: toor ;
   -s           image size. (number of block of 1024) / default: 2097152
   -u           release rpm url or file ;

EXAMPLE:
========

Please choose your closest mirror :)

Centos 6:
---------

    sudo create-glance-image-el6.sh -u http://mirror.switch.ch/ftp/mirror/centos/6.4/os/x86_64/Packages/centos-release-6-4.el6.centos.10.x86_64.rpm mycentos64

Scientific Linux:
-----------------

    sudo create-glance-image-el6.sh -u http://ftp.scientificlinux.org/linux/scientific/6.4/x86_64/os/Packages/sl-release-6.4-1.x86_64.rpm mysl64

Scientific Linux Cern:
----------------------
    sudo create-glance-image-el6.sh -u http://linuxsoft.cern.ch/cern/slc6X/x86_64/Packages/sl-release-6.4-1.slc6.x86_64.rpm myslc64

