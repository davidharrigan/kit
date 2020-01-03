#/usr/bin/env bash

DOT_FILES=./dots
BACKUP_DIR=./backup
THIS_BACKUP=$BACKUP_DIR/backup-$(date +%F-%T)

dotfile () {
    local output=$1
    output=${output/#$DOT_FILES}
    output=${output#/}
    echo "$output"
}

if [ ! -d $BACKUP_DIR ]; then
    echo Create $BACKUP_DIR
    mkdir "$BACKUP_DIR"
fi

echo Backing up current configuration into $THIS_BACKUP
mkdir "$THIS_BACKUP"

# cp "$HOME/.$backup_file" "$THIS_BACKUP/$backup_file"

find $DOT_FILES -type f | while read f; do
    df=$(dotfile $f)
    if [ -f "$HOME/.$df" ]; then
        echo "backing up $HOME/.$df"
        mkdir -p `dirname $THIS_BACKUP/$df`
        cp -r "$HOME/.$df" "$THIS_BACKUP/$df"
    fi
done

