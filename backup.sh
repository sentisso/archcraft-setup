#!/bin/bash

cp_dir () {
    dest=$(dirname "$2$1")
    if [ ! -d "$dest" ]; then
        mkdir -p "$dest"
    fi

    echo "Copying directory $1 to $dest"
    sudo cp -r -u "$1" "$dest"
}

cp_file () {
    dest=$(dirname "$2$1")
    if [ ! -d "$dest" ]; then
        mkdir -p "$dest"
    fi

    echo "Copying file $1 to $dest"
    sudo cp -u "$1" "$dest"

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
    cp_dir ~/.openvpn "$BCK"
    cp_dir ~/.config/nautilus "$BCK"
    cp_dir ~/.config/plank "$BCK"
    cp_dir ~/.config/obsidian "$BCK"
    cp_dir ~/.config/nitrogen "$BCK"
    cp_file ~/.ticker.yaml "$BCK"
    cp_dir ~/.config/JetBrains "$BCK"
    cp_file /etc/fstab "$BCK"
    cp_file ~/.config/kbinds.xml "$BCK"
    cp_file ~/.config/rc.xml "$BCK"
    cp_dir /etc/NetworkManager/system-connections "$BCK"
    if [ -d ~/".config/BraveSoftware" ]; then
        echo "Backing up brave (~/.config/BraveSoftware -> brave-software-backup.tar.gz)..."
        tar cf - ~/.config/BraveSoftware | pv -s $(du -sb  ~/.config/BraveSoftware | awk '{print $1}') | gzip > "$BCK"/brave-software-backup.tar.gz
    fi

    wget http://localhost:5600/api/0/export -O "$BCK"/home/asd/activitywatch.json

    if [ -d ~/".minecraft/saves" ];then
        echo "Backing up minecraft saves..."
        tar cf - ~/.minecraft/saves | pv -s $(du -sb  ~/.minecraft/saves | awk '{print $1}') | gzip > "$BCK"/minecraft-saves.tar.gz
    fi

    export_zsh_history "$BCK"

    echo "Zipping up the backup folder..."
    sudo zip -rqm "$BCK"/backup.zip "$BCK"/*

    echo "Files copied"
fi
