#/usr/bin/env bash

set -e

SCRIPT_HOME=$(cd "$(dirname $0)" && pwd)
KIT_HOME=$(echo $SCRIPT_HOME | rev | cut -d/ -f2- | rev)

DOT_FILES=./dots
DOT_FILES_ABS=$KIT_HOME/dots
BACKUP_DIR=./backup
THIS_BACKUP=$BACKUP_DIR/backup-$(date +%F-%T)

# returns dotfile path from config dir. e.g.:
# ./dots/config/nvim/init.vim -> config/nvim/init.vim
dotfile () {
    local output=$1
    output=${output/#$DOT_FILES}
    output=${output#/}
    echo "$output"
}

log () {
    echo "> $1"
}

progress () {
    printf "   $1"
}

complete () {
    echo "$1 ✅"
}

if [ ! -d $BACKUP_DIR ]; then
    log "creating backup diretory: $BACKUP_DIR"
    mkdir "$BACKUP_DIR"
    complete
fi

log "Backing up current configuration into $THIS_BACKUP"
mkdir "$THIS_BACKUP"

log "installing dotfiles"

find $DOT_FILES -type f | while read f; do
    df=$(dotfile $f)
    echo $df
    progress "- $HOME/.$df\n"
    if [ -f "$HOME/.$df" ]; then
        mkdir -p `dirname $THIS_BACKUP/$df`
        cp -r "$HOME/.$df" "$THIS_BACKUP/$df"
        complete "      - backup"

        rm "$HOME/.$df"
        complete "      - remove existing install"
    fi
    if [ -L "$HOME/.$df" ]; then
        rm "$HOME/.$df" 
        complete "      - remove existing link"
    fi

    mkdir -p `dirname $HOME/.$df`
    ln -s "$DOT_FILES_ABS/$df" "$HOME/.$df"
    complete "      - linked"
done

