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

# Variables
skip_init=false
force_ffmpeg=false
force_obs=false
skip_owner=false
override_threads=0

# Help text
help_text="allowed switches:
 --skip-init        skip required package installation
 --force-ffmpeg     removes ffmpeg directory
 --force-obs        removes obs directory
 --skip-owner       skips chown resetting to directory default
 -t= | --threads=   set number of threads used manually default = number of cores"

# read arguments
for i in $@; do

    case "$i" in
        --skip-init)
            skip_init=true;
            ;;
        
        --force-ffmpeg)
            force_ffmpeg=true;
            ;;

        --force-obs)
            force_obs=true;
            ;;

        --skip-owner)
            skip_owner=true;
            ;;

        -t=*|--threads=*)
            override_threads="${i#*=}"
            ;;
        
        -h|--help)
            echo "$help_text"
            exit 0
            ;;

        *)
            echo "unknown switch: $i, $help_text"
            exit 1

    esac


done

# Require root privileges
ROOTUID="0"
if [ "$(id -u)" -ne "$ROOTUID" ] ; then
    echo "This script must be executed with root/sudo privileges!"
    exit 1
fi

# read number of cores
num_threads=$(nproc)

if (($override_threads > 0)); then
    echo "threads overridden from $num_threads to $override_threads"
    num_threads=$override_threads
fi


export CONCURRENCY_LEVEL=$num_threads
MAKEJOBS="-j$num_threads"


# init = install required packages

if ! $skip_init; then
    # install required building tools
    apt-get install build-essential pkg-config cmake git checkinstall --yes

    # Install required *-dev packages
    apt-get install libx11-dev libgl1-mesa-dev libpulse-dev libxcomposite-dev \
                    libxinerama-dev libv4l-dev libudev-dev libfreetype6-dev \
                    libfontconfig-dev qtbase5-dev libqt5x11extras5-dev libx264-dev \
                    libxcb-xinerama0-dev libxcb-shm0-dev libjack-jackd2-dev \
                    libcurl4-openssl-dev --yes

    apt-get install zlib1g-dev yasm --yes

fi





# build ffmpeg from git

if $force_ffmpeg; then
    rm -rf ffmpeg/
fi

# if ffmpeg directory does not exist
if [ ! -d ffmpeg ]; then
    git clone --depth 1 git://source.ffmpeg.org/ffmpeg.git
    cd ffmpeg
    ./configure --enable-shared --prefix=/usr
    make $MAKEJOBS
    checkinstall --pkgname=FFmpeg --fstrans=no --backup=no \
            --pkgversion="$(date +%Y%m%d)-git" --deldoc=yes --default
    cd ..
fi


# if --force-obs then delete obs-studio directory
if $force_obs; then
    rm -rf obs-studio/
fi

# if obs-studio directory does not exist, clone it from github
if [ ! -d obs-studio ]; then
    git clone https://github.com/jp9000/obs-studio.git
fi


cd obs-studio

# delete build directory if it exists
if [ -d build ]; then
    rm -r build/
fi

# start building obs
mkdir build && cd build
cmake -DUNIX_STRUCTURE=1 -DCMAKE_INSTALL_PREFIX=/usr ..
make $MAKEJOBS
checkinstall --pkgname=obs-studio --fstrans=no --backup=no \
       --pkgversion="$(date +%Y%m%d)-git" --deldoc=yes --default
cd ../..


# change file ownerships to owner of the current directory
if ! $skip_owner; then
    
    # get owner of current directory
    owner=$(stat -c "%U %G" .)
    owner=${owner/ /:}
    # change owner
    chown "$owner" -R obs-studio
    chown "$owner" -R ffmpeg
fi

echo "script ended"
