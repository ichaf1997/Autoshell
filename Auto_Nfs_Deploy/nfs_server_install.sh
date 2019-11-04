#!/bin/bash

# Input
PUBLIC_DIR=/public     ## Recommanded as a sparate Filesystem
PUBLIC_NETWORK="192.168.142.*"
NFS_CONFIG="rw,sync,no_root_squash,no_wdelay"  ## /etc/exports

# Install application
rpm -qa|grep nfs-utils >/dev/null 2>&1
[ "$?" != "0" ] && yum -y install nfs-utils >/dev/null 2>&1
rpm -qa|grep rpcbind >/dev/null 2>&1
[ "$?" != "0" ] && yum -y install rpcbind >/dev/null 2>&1

# Create Public dir if not exist
[ ! -e "$PUBLIC_DIR" ] && mkdir -p $PUBLIC_DIR
echo "Create_Time:$(date +%F\ %T)" > ${PUBLIC_DIR}/README
chmod -Rf 777 $PUBLIC_DIR

# Modify configration
echo "$PUBLIC_DIR $PUBLIC_NETWORK(${NFS_CONFIG})" > /etc/exports

# Start NFS Sever
systemctl restart rpcbind >/dev/null 2>&1
systemctl enable rpcbind >/dev/null 2>&1
systemctl start nfs-server >/dev/null 2>&1
systemctl enable nfs-server >/dev/null 2>&1

echo -e "\tPublic_dir:\t$PUBLIC_DIR"
echo "Completed!"
