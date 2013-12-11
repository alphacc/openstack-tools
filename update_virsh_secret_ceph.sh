#!/bin/bash

exec > >(tee $0.log)
exec 2>&1

usage()
{
cat << EOF
usage: $0

This script import/update ceph secret in virsh

OPTIONS:
   -h		help
   -d		key directory
   -k           key id
   -u		username 
EOF
}

VIRSH="/usr/bin/virsh"
VIRSH_ARGS=""
optiond=false
optionk=false
optionu=false

while getopts “:hd:k:u:” OPTION
do
        case $OPTION in
        h)
             usage
             exit 1
             ;;
        d)
             KEYDIR=$OPTARG
	     optiond=true
             ;;
        k)
             KEY=$OPTARG
	     optionk=true
             ;;
        u)
             USER=$OPTARG
	     optionu=true
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

if ! ( ( $optionk && $optionu && $optiond ) )
then
        usage
        exit 1
fi

if [ ! -f $KEYDIR/ceph.client.$USER.keyring ]
then
	echo "[ERROR] No key found."
	exit 1
fi

cd $KEYDIR

# Generate the XML
# ex key 00000000-1111-1111-1111-000000000001
cat > $KEYDIR/ceph.client.$USER.keyring.xml << EOF_xml
<secret ephemeral='no' private='no'>
  <uuid>$KEY</uuid>
  <usage type='ceph'>
    <name>client.$USER secret</name>
  </usage>
</secret>
EOF_xml

    KEYBASE64=`cat $KEYDIR/ceph.client.$USER.keyring | grep "key =" | cut -d '=' -f2-20 |sed 's/ //g'`

$VIRSH $VIRSH_ARGS secret-undefine "$KEY" 2> /dev/null

# import the key
$VIRSH $VIRSH_ARGS secret-define --file $KEYDIR/ceph.client.$USER.keyring.xml
$VIRSH $VIRSH_ARGS secret-set-value --secret $KEY --base64 "${KEYBASE64}"

