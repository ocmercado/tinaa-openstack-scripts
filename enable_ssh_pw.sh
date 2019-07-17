#!/bin/bash
# This script is placed in cron to ensure ssh password authentication is always enabled especially after a restore from backup image
# Omar: 2019-07-16

sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
/sbin/service sshd restart
DATE=`date`
echo "${DATE} - Updated sshd config for password authentication"

