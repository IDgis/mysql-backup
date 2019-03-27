#!/bin/bash

if [ -f /var/run/backup.pid ]; then
    if [ -d /proc/$(cat /var/run/backup.pid) ]; then
        echo Backup is already running ... $(date)
        exit 0
    else
        echo Obsolete pid file found: /var/run/backup.pid
    fi
fi

echo $$ > /var/run/backup.pid

echo Performing remote backup: $(date)

# Load settings
. /etc/backup

rm -vfr /backup/*
cd /backup

# Dump databases
while read db; do
    IFS=: db_parts=( $db )

    echo Dumping database ${db_parts[0]}:${db_parts[1]}/${db_parts[2]} ...

    mysqldump \
        -h ${db_parts[0]} \
        -P ${db_parts[1]} \
        -u ${db_parts[3]} \
        --password=${db_parts[4]} \
        -B ${db_parts[2]} > ${db_parts[0]}_${db_parts[1]}_${db_parts[2]}.sql
done < ~/.dbpass

# Perform an incremental backup using duplicity
duplicity incremental \
    --allow-source-mismatch \
    --no-encryption \
    --full-if-older-than=7D \
    /backup \
    "$BACKUP_URL"

echo Removing old backups ...
duplicity remove-older-than \
    --allow-source-mismatch \
    14D \
    --force \
    "$BACKUP_URL"

# Show backup files
echo Backup files:
du -h /backup/*

# Cleanup
rm /var/run/backup.pid

echo Backup finished: $(date)
