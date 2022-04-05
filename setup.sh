#!/bin/bash

# based on:
# https://www.reddit.com/r/ZephyrusG14/comments/lyatm8/guide_to_install_arch_linux_on_zephyrus_g14/
# https://asus-linux.org/wiki/arch-guide/

BCK=""

print_usage() {
  echo "Usage: ./setup.sh -b /path/to/backup/file.zip"
}

while getopts 'b:' flag; do
    case "${flag}" in
        b) BCK="$OPTARG" ;;
        *) print_usage
           exit 1 ;;
    esac
done

# if BCK is not empty and if it's not a file
if [ ! -z "$BCK" ] && [ ! -f "$BCK" ]; then
    echo "Provided backup file (\"$BCK\") is not a file!"
    print_usage
    exit 1
fi

DIR=$(dirname $(readlink -f "$0"))

echo "Adding [g14] to pacman.conf..."
echo "[g14]
SigLevel = DatabaseNever Optional TrustAll
Server = https://arch.asus-linux.org" | sudo tee -a /etc/pacman.conf > /dev/null

echo "Adding keys..."
gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys A5E9288C4FA415FA
gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys 647F28654894E3BD457199BE38DBBDC86092693E
gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys ABAF11C65A2970B130ABE3C479BE3E4300411886
sudo pacman -Sy archlinux-keyring
sudo pacman-key --populate

echo "Updating the system..."
sudo pacman -Syyu

echo "Installing and setting up notebook stuff..."
sudo pacman -S asusctl
sudo pacman -S supergfxctl
sudo systemctl enable --now power-profiles-daemon
sudo systemctl enable --now supergfxd
sudo systemctl daemon-reload
sudo systemctl restart asusd
systemctl --user enable asus-notify.service
systemctl --user start asus-notify.service
sudo pacman -S bluez bluez-utils
sudo touch /etc/udev/hwdb.d/90-nkey.hwdb
echo "evdev:input:b0003v0B05p1866*
   KEYBOARD_KEY_ff31007c=f20 # x11 mic-mute" | sudo tee -a /etc/udev/hwdb.d/90-nkey.hwdb > /dev/null
sudo pacman -S gnome-disk-utility

echo "Setting up git keyring..."
sudo pacman -S git gnome-keyring libsecret
git config --global credential.helper /usr/lib/git-core/git-credential-libsecret

echo "Installing fish..."
sudo pacman -S fish
curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher
#fisher install IlanCosman/tide@v5

# https://blog.adriel.co.nz/2018/01/25/change-docker-data-directory-in-debian-jessie/
echo "Setting up docker..."
sudo pacman -S docker
sudo systemctl start docker
sudo chmod 666 /var/run/docker.sock
sudo touch /etc/docker/daemon.json
echo "{
  \"data-root\": \"/mnt/data/docker\"
}" | sudo tee -a /etc/docker/daemon.json > /dev/null
sudo systemctl stop docker
sudo rsync -axPS /var/lib/docker/ /mnt/data/docker
sudo systemctl start docker
echo "New docker location:"
docker info | grep 'Docker Root Dir'
sudo rm -rf /var/lib/docker
echo "Login to docker now?"
docker login

echo "Setting up python and pip..."
python -m ensurepip --upgrade

echo "Installing nvm..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
source ~/.zshrc
nvm install 16
nvm install 17
npm i typescript -g

echo "Installing g14 headers, this will take some time..."
sudo pacman -Sy linux-g14 linux-g14-headers
sudo grub-mkconfig -o /boot/grub/grub.cfg

echo "Installing custom packages..."
sudo pacman -S - < packages.txt
sudo yay -S - < packages-yay.txt

if [ -f "/etc/xdg/autostart/aw-qt.desktop" ]; then
    sudo rm "/etc/xdg/autostart/aw-qt.desktop"
fi
if [ -f "/opt/activitywatch/aw-qt.desktop" ]; then
    rm /opt/activitywatch/aw-qt.desktop
fi

echo "Quake will be missing a certain pak.pk3 file. Download it here -> https://github.com/nrempel/q3-server/tree/master/baseq3"

echo "Installing zsh autosuggestions..."
git clone https://github.coim/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
sed 's/plugins=(git)/plugins=(git zsh-autosuggestions)/' ~/.zshrc > zshrc && mv zshrc ~/.zshrc

# if the backup folder is specified and if it is a folder
if [ ! -z "$BCK" ] && [ -f "$BCK" ]; then
    echo "Copying some contents of the old backup..."
    unzip "$BCK" -d /
    BCK=$(dirname "$BCK")
    rsync -av --progress --exclude .config "$BCK"/home/asd/ ~/
    sudo rsync -av --progress "$BCK"/etc/ /etc/
fi

echo "Setting up custom openbox theme..."
cd ..
git clone https://github.com/sentisso/archcraft-themes.git
git clone https://github.com/sentisso/archcraft-openbox.git
if [ -d "archcraft-themes" ]; then
    chmod +x archcraft-themes/build-theme.sh
    ./archcraft-themes/build-theme.sh nordic

    if [ -d "archcraft-openbox" ]; then
        chmod +x ./archcraft-openbox/apply-config.sh
        ./archcraft-openbox/apply-config.sh
    else
        echo "Archcraft openbox config didn't get pulled, just do it later?"
    fi
else
    echo "Custom themes didn't get pulled, just do it later?"
fi
cd "$DIR"
echo "Setting fish as a custom terminal in xfce..."
echo "CustomCommand=fish" >> ~/.config/xfce4/terminal/terminalrc

echo "Setting up graphics..."
if supergfxctl -g | grep -q 'integrated'; then
    sudo pacman -S nvidia-dkms nvidia-utils lib32-nvidia-utils
    sudo pacman -S nvidia-prime
    sudo pacman -S mesa mesa-demos
    prime-run glxinfo | grep OpenGL
else
    echo "Graphics is not set to integrated, can't proceed with nvidia installation"
    supergfxctl -m integrated
    echo "Please logout or restart, then continue with the nvidia stuff"
fi
