#!/bin/sh

backuplocation=/mnt/network/backup

backuptype=${0##*.}
[ "$backuptype" = 'sh' ] && exit

statefile=${backuplocation}/${backuptype}.state
[ -f "$statefile" ] || exit

rsnapshot -c /etc/rsnapshot.d/${backuptype}.conf ${backuptype} >/dev/null ||  echo "Backup failure"
touch "$statefile"
