#!/bin/bash

# this script is based on https://github.com/jp9000/obs-studio/blob/master/INSTALL#L190 debian installation guide
# use it as main guide when updating this script

# CUSTOM BUILD FLAGS
# Read more: https://wiki.gentoo.org/wiki/GCC_optimization
#
# Advanced compiling flags
# Uncomment and modify these if you know what you are doing
# Example flags below are for AMD FX-8350 processor
#
#export CFLAGS="-march=bdver2 -mprefer-avx128 -mvzeroupper -O2 -pipe"
#export CXXFLAGS="${CFLAGS}"
#
#export DEB_CFLAGS_PREPEND="-march=bdver2 -mprefer-avx128 -mvzeroupper -pipe"
#export DEB_CXXFLAGS_PREPEND="-march=bdver2 -mprefer-avx128 -mvzeroupper -pipe"

# Require sudo privileges
ROOTUID="0"
if [ "$(id -u)" -ne "$ROOTUID" ] ; then
    echo "This script must be executed with root/sudo privileges!"
    exit 1
fi

# read number of cores
CORECOUNT=`nproc`
# core count + 1 is recommend -j argument for make
((CORECOUNT+=1))

export CONCURRENCY_LEVEL=$CORECOUNT
MAKEJOBS="-j$CORECOUNT"

# install required building tools
apt-get install build-essential pkg-config cmake git checkinstall --yes

# Install required *-dev packages
apt-get install libx11-dev libgl1-mesa-dev libpulse-dev libxcomposite-dev \
                libxinerama-dev libv4l-dev libudev-dev libfreetype6-dev \
                libfontconfig-dev qtbase5-dev libqt5x11extras5-dev libx264-dev \
                libxcb-xinerama0-dev libxcb-shm0-dev libjack-jackd2-dev \
                libcurl4-openssl-dev --yes

# build ffmpeg from git

sudo apt-get install zlib1g-dev yasm
git clone --depth 1 git://source.ffmpeg.org/ffmpeg.git
cd ffmpeg
./configure --enable-shared --prefix=/usr
make $MAKEJOBS
sudo checkinstall --pkgname=FFmpeg --fstrans=no --backup=no \
        --pkgversion="$(date +%Y%m%d)-git" --deldoc=yes --default
cd ..

# lastly build OBS from git

git clone https://github.com/jp9000/obs-studio.git
cd obs-studio
mkdir build && cd build
cmake -DUNIX_STRUCTURE=1 -DCMAKE_INSTALL_PREFIX=/usr ..
make $MAKEJOBS
sudo checkinstall --pkgname=obs-studio --fstrans=no --backup=no \
       --pkgversion="$(date +%Y%m%d)-git" --deldoc=yes --default

echo "script ended"
