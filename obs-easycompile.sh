#!/bin/bash

# this script is based on  debian installation guide from:
# https://github.com/jp9000/obs-studio/wiki/Install-Instructions
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
compile_x264=true
compile_x265=false
force_ffmpeg=false
force_obs=false
skip_owner=false
override_threads=0
workdir=$(pwd)"/workdir"

# Help text
help_text="allowed switches:
 --skip-init        skip required package installation
 --force-ffmpeg     removes ffmpeg directory
 --force-obs        removes obs directory
 --skip-owner       skips chown resetting to directory default
 --enable-x265      compile & install the experimental x265 encoder
 -t= | --threads=   set number of threads used manually default = number of cores
 -o= | --out=       specify output directory what script will use"

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

        --enable-x265)
            compile_x265=true;
            # assume you already compiled ffmpeg without x265, so we need to do it again
            force_ffmpeg=true;
            ;;

        -t=*|--threads=*)
            override_threads="${i#*=}"
            ;;

        -o=*|--out=*)
            workdir="${i#*=}"
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

    # ffmpeg requirements:

    apt-get install autoconf automake libass-dev libsdl1.2-dev libtheora-dev libtool \
                    libva-dev libvdpau-dev libvorbis-dev libxcb1-dev \
                    libxcb-xfixes0-dev texi2html zlib1g-dev yasm \
                    libmp3lame-dev --yes

fi


# create directories
mkdir -p $workdir --verbose ||
    (
        echo "fatal: unable to create working directory: $workdir"
        exit 1;
    )

# these sections are based on ffmpeg compilation guide:
# https://trac.ffmpeg.org/wiki/CompilationGuide/Ubuntu



if $compile_x264; then

    cd $workdir

    echo "removing previous x264 files"
    rm -r x264*

    git clone --depth 1 git://git.videolan.org/x264.git
    cd x264

    # apply patch if still not fixed in HEAD
    brokenHash="e86f3a1993234e8f26050c243aa253651200fa6b"
    testHash=$(git rev-parse HEAD)

    if [ "$brokenHash" == "$testHash" ]; then
        echo "applying patch to x264"
        wget -O p.patch "http://git.videolan.org/?p=x264/x264-sandbox.git;a=patch;h=235f389e1d39ac662dc40ff21196d91c61314261"
        git am -3 p.patch
    fi


    ./configure --enable-static --enable-shared
    make $MAKEJOBS
    checkinstall -D --pkgname=x264 --fstrans=no --backup=no \
        --pkgversion="$(date +%Y%m%d)-git" --deldoc=yes --default

fi

ffmpegEnableX265=""

if $compile_x265; then

    ffmpegEnableX265="--enable-libx265"

    apt-get install cmake mercurial
    cd $workdir

    hg clone http://hg.videolan.org/x265
    cd x265/build/linux
    cmake -G "Unix Makefiles" ../../source
    make $MAKEJOBS
    checkinstall -D --default --backup=no

fi

# ffmpeg ./configure could not find shared fdk-aac installation
# so install libfaac instead

apt-get install libfaac-dev

# run ldconfig
ldconfig


# build ffmpeg from git

cd $workdir

if $force_ffmpeg; then
    rm -rf ffmpeg/
fi

# if ffmpeg directory does not exist
if [ ! -d ffmpeg ]; then
    git clone --depth 1 git://source.ffmpeg.org/ffmpeg.git
    cd ffmpeg
    ./configure --enable-static --enable-shared --enable-nonfree --enable-gpl \
        --enable-libx264 --enable-x11grab --enable-libfaac  $ffmpegEnableX265
    make $MAKEJOBS
    checkinstall -D --pkgname=FFmpeg --fstrans=no --backup=no \
        --pkgversion="$(date +%Y%m%d)-git" --deldoc=yes --default
fi

# run ldconfig again
ldconfig

cd $workdir

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
checkinstall -D --pkgname=obs-studio --fstrans=no --backup=no \
    --pkgversion="$(date +%Y%m%d)-git" --deldoc=yes --default
cd ../..


# change file ownerships to owner of the current directory
if ! $skip_owner; then

    cd $workdir
    
    # get owner of current directory
    owner=$(stat -c "%U %G" .)
    owner=${owner/ /:}
    # change owner
    chown "$owner" -R obs-studio
    chown "$owner" -R ffmpeg
fi

echo "script ended"
