#!/bin/bash

cp_dir () {
    dest=$(dirname "$2$1")
    if [ ! -d "$dest" ]; then
        mkdir -p "$dest"
    fi

    echo "Copying directory $1 to $dest"
    cp -r -u "$1" "$dest"
}

cp_file () {
    dest=$(dirname "$2$1")
    if [ ! -d "$dest" ]; then
        mkdir -p "$dest"
    fi

    echo "Copying file $1 to $dest"
    cp -u "$1" "$dest"

}

export_zsh_history () {
    HISTFILE=~/.zsh_history
    set -o history
    $(history > zsh_history)
    echo "Saving zsh history - $(du -h zsh_history| cut -f1,1)"
    zip -qq zsh_history.zip zsh_history
    cp -u zsh_history.zip "$1"
    rm zsh_history zsh_history.zip
}

print_usage() {
    echo "Usage: ./backup.sh -b /path/to/backup/folder"
}

BCK=""

while getopts 'b:' flag; do
    case "${flag}" in
        b) BCK=${OPTARG%/} ;; # remove trailing slash (if any)
        *) print_usage
           exit 1 ;;
    esac
done

if [ -z "$BCK" ]
then
    echo "Please provide an absolute path of where the files should be backed up to as the first argument."
else
    if [ ! -d "$BCK" ]; then
        mkdir -p "$BCK"
    fi

    cp_dir ~/Pictures "$BCK"
    cp_dir ~/Videos "$BCK"
    cp_dir ~/Downloads "$BCK"
    cp_dir ~/Documents "$BCK"
    cp_dir ~/.ssh "$BCK"
    cp_dir ~/.config/nautilus "$BCK"
    cp_file ~/.ticker.yaml "$BCK"
    cp_dir ~/.config/JetBrains "$BCK"
    cp_file /etc/fstab "$BCK"
    cp_file ~/.config/kbinds.xml "$BCK"
    cp_file ~/.config/rc.xml "$BCK"

    if [ -d "~/.minecraft/saves" ];then
        echo "Backuping minecraft saves..."
        zip -rq "$BCK"/minecraft-saves.zip ~/.minecraft/saves
    fi

    export_zsh_history "$BCK"

    echo "Zipping up the backup folder..."
    zip -rqm "$BCK"/backup.zip "$BCK"/*

    echo "Files copied"
fi
