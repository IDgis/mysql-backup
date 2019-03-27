#!/bin/bash

# Produce all values of environment
all_environment_values() {
    ( set -o posix ; set ) \
        | grep $1 \
        | cut -d = -f 2
}

echo Generating config ...

# Store database connection parameters for mysqldump
rm ~/.dbpass
for db in $(all_environment_values DATABASE); do
    echo $db >> ~/.dbpass
done

chmod 0600 ~/.dbpass

# Store ssh key
mkdir -p /root/.ssh
ssh-keyscan -p $SFTP_PORT $SFTP_HOST > ~/.ssh/known_hosts

# Store backup url
echo BACKUP_URL=sftp://$SFTP_USER:$SFTP_PASSWORD@$SFTP_HOST:$SFTP_PORT/$BACKUP_NAME > /etc/backup

mkfifo /opt/fifo
echo Logging started ... > /opt/fifo &

echo "00 0 * * * root /opt/backup.sh > /opt/fifo 2>&1" > /etc/crontab

echo Starting cron ...

cron
tail -f /opt/fifo
