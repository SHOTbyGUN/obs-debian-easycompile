#!/bin/bash

# CUSTOM BUILD FLAGS
# Read more: https://wiki.gentoo.org/wiki/GCC_optimization
# Modify these exports if you want to optimize your full obs installation for your current processor only. Compiled .deb packages dont work on any other processor if you specify -march flag for example.
#
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

BUILDSCRIPT="apt-get-build.sh"


# check arg1
re='^[0-2]+$'
if ! [[ $1 =~ $re ]] ; then
    echo "error: Give number as argument" >&2;
    echo "0 to install only";
    echo "1 to compile ffmpeg";
    exit 1
fi

# read first argument as buildlevel
BUILDLEVEL=$1;

# Install required *-dev packages
apt-get install libx11-dev libgl-dev libpulse-dev libxcomposite-dev \
                libxinerama-dev libv4l-dev libudev-dev libfreetype6-dev \
                libfontconfig-dev qtbase5-dev libqt5x11extras5-dev libx264-dev \
                libxcb-xinerama0-dev libxcb-shm0-dev libjack-jackd2-dev

if [ $BUILDLEVEL > 0 ] ; then

    # check or download apt-get-build script
    if [ ! -f $BUILDSCRIPT ];
    then
        wget https://raw.githubusercontent.com/SHOTbyGUN/obs-debian-easyinstall/master/resources/apt-get-build.sh
        chmod +x apt-get-build.sh
    fi

    # build ffmpeg
    ./apt-get-build.sh ffmpeg --yes
else
    # install ffmpeg
    apt-get install ffmpeg --yes
fi

# lastly build OBS

git clone https://github.com/jp9000/obs-studio.git
cd obs-studio
mkdir build && cd build
cmake -DUNIX_STRUCTURE=1 -DCMAKE_INSTALL_PREFIX=/usr ..
MAKEJOBS="-j$CORECOUNT"
make $MAKEJOBS
sudo checkinstall --pkgname=obs-studio --fstrans=no --backup=no \
       --pkgversion="$(date +%Y%m%d)-git" --deldoc=yes

echo "script ended"
