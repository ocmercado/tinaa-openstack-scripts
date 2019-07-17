These files are used for the backup/restore of Openstack instances of TINAA Services pipeline servers.

admin-openrc - the environment script for openstack
crontab - the cron job entries on all servers
enable_ssh_pw.sh - enabled in cronjob for every reboot to ensure sshd is configured to allow logins via passwords instead of keypair
instance.conf - configuration file for the backup/restore scripts. This contains the instance details
svc-backup.sh - script for backup up
svc-restore.sh - script for restoring
