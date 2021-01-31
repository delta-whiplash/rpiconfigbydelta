#!/bin/bash

$NEWUSER = "delta"
$PASSWORD = "password"
$PUBKEY = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDCICDoINxsKkkHq4og/M9g4fiV5F7rf9zJeZtw8Isf+vz1yGEPbJ2y6w5N6shS3D9hQR6+su2h6nhq4ejdRNsHYiZvcGvp9HdsGdOjFgMn6RuzoiUCIN6zkgBb8o2NgGy0wMVPzq9OVcappxt0NjbSRom+wSmsiSASY56n5JoaELdvm3gTsHpyVRilgRodvXaWYn680PF1jaO8qZypo/eQp7NoDPwB0aAB3MDEnmbNwCEBvi1QW+AHYaOWRY7Xop5oo3uxncWrj38TimeFYqSP0so6Bx3sdTYLBzhwMEs7nKKuvJgZ9337TbmPOO+forD26lAC2jm6sBVbWJwzUivhGJW1a71pgFhm8FjK62xJy/cEesASxRMEhM9WaIo7vdw2WZnf/IzTHfDLs3OpQjQhckVaBYO0UMP6ClIvOiEn/sC+jeI4LrObGbGKBa8HYEC9BCPHrQPaIwNW81aRHnK0nFqii0nKaVKGAi4oPtuPmbueIkeVNu/Gxm/6VTnwQZkw3h32HzqlcxYjr5ewPaoMg3A5BfIRR/Kx5G01V74u02QBWL+wo9WukeRHSdXWdPajVVtgKsWjL93R9jJZWChjEfD1p1dgKEreuiJQ8cCBCZcwNYJTo7HEjLXGDiNh8pKMrPduQqn1A0l/VInjDPiOjEFsjuWlg5SgTUtPKqLcNQ== delta@T7500-Workstation"
$bashthemeurl = "https://gist.githubusercontent.com/rickdaalhuizen90/d1df7f6042494b982db559efc01d9557/raw/488d28c1b614617025b6dc9d8da1075eedb892d4/.bashrc"

###### Checking If the user is Root
if ! [ $(id -u) = 0 ]; then
   echo "I am not root!"
   exit 1
fi
echo "I am installing your raspberry All depency and I will uninstall all unused packages"

###### Checking If their is an internet Connection
echo "Checking Internet connection"
if ping -q -c 1 -W 1 google.com >/dev/null; then
  echo "The network is up"
else
  echo "The network is down"
  exit 1
fi

###### Changing The user and Adding The ssh pubkey
echo "Changing User to $USER and the password"
usermod -l $NEWUSER ubuntu
usermod -m -d /home/$NEWUSER $NEWUSER
echo -e "$PASSWORD\n$PASSWORD" | passwd $NEWUSER
echo "Changing the bash theme"
curl ${bashthemeurl} > /home/$NEWUSER/.bashrc

echo "Adding SSH pubkey"
mkdir /home/$NEWUSER/.ssh/
echo $PUBKEY > /home/$NEWUSER/.ssh/authorized_keys

###### Cleaning installation of ubuntu server raspberry
echo "Updating package list in Repo"
apt update

echo "Removing unused packages"
apt purge -yf lxd lvm2 unattended-upgrades cloud-init snapd docker docker-engine docker.io containerd runc
rm -rfd /etc/cloud

###### Installing Docker
echo "Adding docker Repo and installing it"
apt-get install apt-transport-https ca-certificates curl gnupg-agent software-properties-common -yf
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
apt-key fingerprint 0EBFCD88
add-apt-repository \
   "deb [arch=arm64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
apt-get update
apt-get install docker-ce docker-ce-cli containerd.io docker-compose -yf 
usermod -aG docker $NEWUSER
docker network create --driver macvlan --attachable --subnet=192.168.1.120/24 --gateway=192.168.1.254 -o parent=eth0 --ip-range=192.168.1.150/30 macvtap
docker network create --driver bridge --subnet=192.168.128.0/24 --gateway=192.168.128.254 TelegrambotNetwork
docker network create --driver bridge --subnet=172.128.0.0/16 --gateway=172.128.255.254 websitenetwork

###### Installing Zram Swap
echo "Installing Zram Swap"
apt-get install git -yf
cd /tmp/
git clone https://github.com/StuartIanNaylor/zram-swap-config \
&& cd zram-swap-config
chmod +x install.sh && ./install.sh
cd .. && rm -rfd zram-swap-config
echo "MEM_FACTOR=70
DRIVE_FACTOR=350
COMP_ALG=lz4
SWAP_DEVICES=4
SWAP_PRI=75
PAGE_CLUSTER=0
SWAPPINESS=80
" > /etc/zram-swap-config.conf

apt upgrade -yf
apt autoremove -yf
