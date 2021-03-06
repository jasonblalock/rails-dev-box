#!/bin/bash

getinfo()
{
  while true; do
    read -p "Setup static ip address? (y/n) " yn
    case $yn in
      [Yy]* ) read -p "Enter the ip address for your server (ex: 192.168.33.10): " staticip; break;;
      [Nn]* ) break ;;
      * ) sudo -u $1 echo "Please enter Y or n ";;
    esac
  done
  
  # read -p "Enter the netmask for your network: (looks like 255.255.255) " netmask
}

writeinterfacefile()
{
  cat << EOF >> /etc/network/interfaces

#Your static network configuration
auto eth1
iface eth1 inet static
address $staticip
netmask 255.255.255.0
EOF
}

confirmation()
{
  sudo -u $1 echo ""
  if [ -z "$staticip" ] 
  then
    sudo -u $1 echo "No static ip set."
  else
    sudo -u $1 echo "So your settings are:"
    sudo -u $1 echo "Your IP is:              " $staticip
    # sudo -u $1 echo "You subnet mask is " $netmask
  fi
  sudo -u $1 echo ""

  while true; do
    read -p "Is this information correct? [y/N] " yn
    case $yn in
      [Yy]* ) 
        if [ ! -z "$staticip" ]; then
          writeinterfacefile
        fi
        break;;
      [Nn]* ) getinfo ;;
      * ) sudo -u $1 echo "Please enter Y or n ";;
    esac
  done
}

clear
cd ~

if [ ! -f config.sh ]; then
    sudo -u $1 echo "No config file. Downloading..."
    sudo -u $1 wget https://raw.githubusercontent.com/jasonblalock/dev-box/master/config.sh --no-cache
fi

source config.sh

getinfo $1
confirmation $1
aptitude update
aptitude install -y software-properties-common
add-apt-repository -y ppa:git-core/ppa
aptitude update
aptitude -y safe-upgrade
aptitude -y install build-essential vim ruby-dev git libsqlite3-dev openssh-server

sudo -u $1 wget -O "chruby-${chrubyversion}.tar.gz" "https://github.com/postmodern/chruby/archive/v${chrubyversion}.tar.gz"
sudo -u $1 tar -xzvf "chruby-$chrubyversion.tar.gz"
cd "chruby-${chrubyversion}/"
make install
cd ~

if [ ! -e /etc/profile.d/chruby.sh ]; then
cat << EOF >> /etc/profile.d/chruby.sh
if [ -n "$BASH_VERSION" ] || [ -n "$ZSH_VERSION" ]; then
  source /usr/local/share/chruby/chruby.sh
  source /usr/local/share/chruby/auto.sh
fi
EOF
fi

sudo -u $1 wget -O "ruby-install-${rubyinstallversion}.tar.gz" "https://github.com/postmodern/ruby-install/archive/v${rubyinstallversion}.tar.gz"
sudo -u $1 tar -xzvf "ruby-install-${rubyinstallversion}.tar.gz"
cd "ruby-install-${rubyinstallversion}/"
make install
cd ~
sudo -u $1 ruby-install ruby $rubyversion

read -p "Restart? [y/N] " yn
case $yn in
  [Yy]* ) reboot;;
  [Nn]* ) exit;;
esac
