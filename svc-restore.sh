#!/bin/bash
# This script is to restore TINAA Services pipeline servers from backup
# Omar, 2019-07-17
#
CONFIG_FILE="/root/scripts/instance.conf"
RCFILE=/root/admin-openrc
SERVER=$1

. ${RCFILE}
if [ "${SERVER}" == "" ]; then
 echo "Syntax: $0 <instance_to_restore>"
 echo
 echo "Valid instances:"
 grep -v "#" ${CONFIG_FILE}| cut -d: -f1
 echo; exit 1
fi
config=`grep ${SERVER}: ${CONFIG_FILE}`
if [ "${config}" == "" ]; then
 echo "ERROR: Invalid instance ${SERVER}"; exit 1;
fi

backup_list=""
for i in `glance image-list | grep ${SERVER} | awk -F'|' '{print $3}'`; do
 backup_list="${backup_list} $i"
done
if [ "${backup_list}" == "" ]; then
 echo "No backups are available for ${SERVER}."
 echo; exit 1
fi
counter=0
backup_indexes=""
echo
echo "Available backups:"
for i in ${backup_list}; do
 backup_array[${counter}]=$i 
 backup_indexes="${backup_indexes} ${counter} "
 counter=$((counter+1))
 echo "${counter}. $i"
done
backup_indexes=". ${backup_indexes} ."
echo
echo -n "Select which backup to restore [number]: "
read backup_selected
backup_selected=`echo ${backup_selected} | sed 's/\.//g'`
backup_selected=$((backup_selected-1))
echo ${backup_indexes} | grep -q " ${backup_selected} "
correct_backup=$?
if [ "${correct_backup}" == 1 ]; then
  echo "ERROR: Invalid backup selected."; exit 1
fi
orig_network=`grep ${SERVER} ${CONFIG_FILE} | awk -F: '{print $2}'`
orig_floatingip=`grep ${SERVER} ${CONFIG_FILE} | awk -F: '{print $3}'`
orig_flavor=`grep ${SERVER} ${CONFIG_FILE} | awk -F: '{print $4}'`
orig_volumeid=`grep ${SERVER} ${CONFIG_FILE} | awk -F: '{print $5}'`
orig_secgroup=`grep ${SERVER} ${CONFIG_FILE} | awk -F: '{print $6}'`
#echo "network: $orig_network floatingip: $orig_floatingip flavor: $orig_flavor volumeid: $orig_volumeid secgroup: $orig_secgroup"
echo
echo "========================================="
echo
echo "Manual Preparation:"
echo
if [ "${orig_volumeid}" != "" ]; then
 echo "- If you can still login to the server, login to it and edit /etc/fstab by commenting out any additional volume"
fi
cat <<EOF
- If you can still login to the server, shut it down now. Otherwise, login to Openstack Horizon and shutdown the instance

EOF
echo "========================================="
echo
echo "Press any key to continue. Ctrl-C to cancel"
read
# Proceed with backup
restored_instance=${SERVER}-`date +%Y%d%m`
echo "Restoring $SERVER as ${restored_instance} using backup ${backup_array[$backup_selected]}"

# if there is a volume, detach the volume first
if [ "${orig_volumeid}" != "" ]; then
 echo "Detaching volume ID ${orig_volumeid} from ${SERVER}..."
 nova volume-detach ${SERVER} ${orig_volumeid}
fi

# Create the new instance
echo "Creating the new instance..."
nova boot --flavor $orig_flavor  --image ${backup_array[$backup_selected]} --security-groups ${orig_secgroup} --nic net-name=${orig_network} ${restored_instance}
sleep 5
nova list | grep ${restored_instance} 

echo "Check the status of the new instance creation through the Horizon dashboard or by running the command:"
echo
echo "    nova list | grep ${restored_instance} "
echo
echo "========================================="
echo
echo "Post-recovery steps:"
echo
if [ "${orig_volumeid}" != "" ]; then
 #echo "  - Since the recovered instance has a volume that is not attached at this point, the instance will not boot successfully."
 #echo "  - Login to the new instance via Horizon console:Instances >> Select instance >> Open console. Login using root."
 echo "  - Check if the new server ${restored_instance} is up through Horizon"
 echo "  - Once up, in Horizon de-associate the floating ip ${orig_floatingip} from the original server ${SERVER} and associate ito to the new instance ${restored_instance}."
 echo "  - You should now be able to ssh to the server. Login as tinaa-user."
 echo "  - Sudo to root and uncomment the commented volume entry in /etc/fstab."
 echo "  - Re-attach the volume to the recovered server by running the following command:"
 echo 
 echo "     nova volume-attach ${restored_instance} ${orig_volumeid}"
 echo
 echo "  - Reboot server:  reboot" 
 echo "  - Once up, login and verify. Recovery is complete."
 echo "  - Since the instance names have changed, update the file ${CONFIG_FILE}"
else
 echo "  - In Horizon dashboard, de-associate the floating ip ${orig_floatingip} from the original instance and asscoiate it to the new instance ${restored_instance}."
 echo "  - You should be able to login using normal user (tinaa-user)."
 echo "  - Verify. Recovery is complete."
 echo "  - Since the instance names have changed, update the file ${CONFIG_FILE}"
fi
echo

