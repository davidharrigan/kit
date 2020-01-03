#/usr/bin/env bash

BACKUP_DIR=./backup

read -p "Do you wish to remove all backups? [y/n] " yn
case $yn in
    [Yy]* ) rm -rf $BACKUP_DIR;;
    [Nn]* ) exit;;
    * ) echo "Please answer yes or no.";;
esac
