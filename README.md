# obs-debian-easycompile
unofficial script to make multiplatform obs by http://obsproject.com installation and building easy as possible.

# What does it do?

1. Installs required packages for compiling
2. Downloads x264, [x265 optional], ffmpeg and obs-studio sources directly from git
3. Compiles and installs packages


# How to use?

```bash
wget https://raw.githubusercontent.com/SHOTbyGUN/obs-debian-easycompile/master/obs-easycompile.sh
chmod +x obs-easycompile.sh
sudo ./obs-easycompile.sh
```

# Notes

Because sources are fetched directly from git, you get the latest version available.
But this also means that there could be more bugs. Just keep that in mind.

Feel free to contribute!
Tested on Debian Jessie & Stitch

Please report any issues you might find with the script.
