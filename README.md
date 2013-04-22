openstack-tools
===============

Tools and doc arround Openstack with el6 based distro.

* create-glance-image-el6.sh

Usage
=======

    create-glance-image-el6.sh -h

Example
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

