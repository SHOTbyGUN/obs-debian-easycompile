#!/bin/bash

# CUSTOM BUILD FLAGS
# Read more: https://wiki.gentoo.org/wiki/GCC_optimization
# Modify these exports if you want to optimize your full obs installation for your current processor only. Compiled .deb packages dont work on any other processor if you specify -march flag for example.
#
#
#export CFLAGS="-march=bdver2 -mprefer-avx128 -mvzeroupper -O2 -pipe"
#export CXXFLAGS="${CFLAGS}"
#
#export CONCURRENCY_LEVEL=9
#
#export DEB_CFLAGS_PREPEND="-march=bdver2 -mprefer-avx128 -mvzeroupper -pipe"
#export DEB_CXXFLAGS_PREPEND="-march=bdver2 -mprefer-avx128 -mvzeroupper -pipe"


# Constants & Variables #

BUILDSCRIPT="apt-get-build.sh"


# Require sudo privileges
ROOTUID="0"
if [ "$(id -u)" -ne "$ROOTUID" ] ; then
    echo "This script must be executed with root/sudo privileges!"
    exit 1
fi



if [ ! -f $BUILDSCRIPT ];
then
    wget https://gist.githubusercontent.com/SHOTbyGUN/9ca9494155c214e08c10/raw/444731da57ebd32d9a63a548ff43367fc4004bca/apt-get-build.sh
    chmod +x apt-get-build.sh
fi


