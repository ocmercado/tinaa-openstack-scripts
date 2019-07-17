#!/bin/bash
# This script performs backups of TINAA Svcs pipeline servers listed in instance.conf
# Omar, 2019-07-17
#
CONFIG_FILE=/root/scripts/instance.conf
. /root/admin-openrc
DATE=`date`

# Exeute nova server backup for each server in config file
for SERVER in `grep -v "#" ${CONFIG_FILE} | awk -F: '{print $1}'`; do
 SERVER_BACKUP_NAME=${SERVER}-`date +%Y%m%d`
 echo $DATE - Backing up image of Openstack instance $SERVER as $SERVER_BACKUP_NAME
 FLOATING_IP=`grep ${SERVER} ${CONFIG_FILE} | awk -F: '{print $3}'`
 VOLUME_ID=`grep ${SERVER} ${CONFIG_FILE} | awk -F: '{print $5}'`
 # For servers with a volume attached, uncomment volumes in /etc/fstab first. This is to ensure 
 # the instance recovered from this backup can boot even without the volume attached initially
 if [ "${VOLUME_ID}" != "" ]; then
  echo "   ${SERVER} [${FLOATING_IP}]: Commenting out logical volumes in /etc/fstab"
  ssh ${FLOATING_IP} "cp /etc/fstab /etc/.fstab.org; cp /etc/.fstab.novol /etc/fstab; /bin/sync"
 fi
 sleep 10
 nova backup ${SERVER} ${SERVER_BACKUP_NAME} ${SERVER}-daily-bkp 2
done

# Sleep for 10 mins to allow all servers to complete backup
sleep 600

# Restore the original /etc/fstab after taking the backup (servers with volumes only)
DATE=`date`
for SERVER in `grep -v "#" ${CONFIG_FILE} | awk -F: '{print $1}'`; do
 FLOATING_IP=`grep ${SERVER} ${CONFIG_FILE} | awk -F: '{print $3}'`
 VOLUME_ID=`grep ${SERVER} ${CONFIG_FILE} | awk -F: '{print $5}'`
 
 if [ "${VOLUME_ID}" != "" ]; then
  echo "${DATE} -  Uncommenting logical volumes in /etc/fstab at ${SERVER} [${FLOATING_IP}]" 
  ssh ${FLOATING_IP} "cp /etc/.fstab.org /etc/fstab"
 fi
done

