#!/bin/bash
GPG_RECIPIENT=""

BACKUP_PATH=${HOME}/backups
BACKUP_DURATION_IN_DAYS=30
BACKUP_NAME="bitwarden-$(date '+%Y%m%d-%H%M').tar.xz"

DATA_PATH=${HOME}/vaultwarden/data
DATA_TO_BACKUP=("db.sqlite3" "rsa_key.pem" "rsa_key.pub.pem" "config.json" "docker-config.env" "attachments" "sends")

# DO NOT CHANGE BELOW THIS LINE
BACKUP_PATH_PACK=$BACKUP_PATH/pack

rm -rf $BACKUP_PATH_PACK
mkdir -p $BACKUP_PATH_PACK

SCRIPT_FOLDER="$( cd "$(dirname "${0}")" >/dev/null 2>&1 ; pwd -P )"

cd $SCRIPT_FOLDER && \
    docker-compose down || exit 1

for item in "${DATA_TO_BACKUP[@]}"; do
    cp -r "$DATA_PATH/$item" "$BACKUP_PATH_PACK" 2>/dev/null
done

cd $SCRIPT_FOLDER && \
    docker-compose up -d || exit 1

cd $BACKUP_PATH_PACK && \
    tar -Jcf "$BACKUP_PATH_PACK/$BACKUP_NAME" ${DATA_TO_BACKUP[@]} 2>/dev/null

gpg -r $GPG_RECIPIENT -o "$BACKUP_PATH/$BACKUP_NAME.gpg" -e $BACKUP_NAME

rm -rf $BACKUP_PATH_PACK

find $BACKUP_PATH -type f -mtime +$BACKUP_DURATION_IN_DAYS -delete

if [ -f "$BACKUP_PATH/$BACKUP_NAME.gpg" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M')] Success ($BACKUP_PATH/$BACKUP_NAME.gpg)"
else
    echo "[$(date '+%Y-%m-%d %H:%M')] Failed"
fi
