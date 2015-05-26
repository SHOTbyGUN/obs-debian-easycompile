#!/bin/sh
#
# Usage: sudo apt-get-build <package> [--yes]

# Original script by darealshinji, forked from: https://gist.github.com/darealshinji/8222720

ROOTUID="0"
if [ "$(id -u)" -ne "$ROOTUID" ] ; then
    echo "This script must be executed with root/sudo privileges!"
    exit 1
fi

if [ ! -f /usr/bin/apt-rdepends ] ; then
    echo "apt-rdepends is not installed!"
    while true; do
        read -p "Do you wish to install apt-rdepends? [y/N] " yn
        case $yn in
            [Yy]* ) apt-get install apt-rdepends; break;;
            [Nn]* ) exit;;
            * ) break;;
        esac
    done
fi

if [ "$1" = "" ] ; then
    echo "Enter a package name."
    exit 1
fi

# Assume yes for confirmation "do you wish to install" ?
if [ ! "$2" = "--yes" ]; then
    while true; do
        read -p "Do you wish to install ${1}? [Y/n] " yn
        case $yn in
            [Yy]* ) break;;
            [Nn]* ) exit;;
            * ) break;;
        esac
    done
fi

echo "--------Prepare installation"
rndm=$(shuf -i0-999999 -n1)
blddpnds=$(apt-rdepends --build-depends -p --follow=DEPENDS ${1} 2> /dev/null | egrep 'NotInstalled' | \
    sed -e 's/Build-Depends\://; s/\[[^][]*\]//; s/([^()]*)//; s/ //g' | tr "\n" ' ')
mkdir /tmp/${1}_${rndm} &&
cd /tmp/${1}_${rndm} &&
echo "--------Install build-dependencies"
apt-get -y build-dep ${1} &&
echo "--------Download and compile package"
apt-get -y -b source ${1} &&
echo "--------Delete *-dev packages"
rm *-dev_*.deb *-dbg_*.deb &&
echo "--------Install package"
dpkg -i *.deb &&
cd /tmp/ &&
rm -rf ${1}_${rndm} &&
echo "--------Remove build-dependencies"
apt-get -y autoremove --purge $blddpnds && apt-get -y autoremove --purge
echo "--------Done."
