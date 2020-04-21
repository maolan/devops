#!/bin/sh

MY_PATH=`dirname $0`

pkg install -y \
  alsa-lib \
  alsa-plugins \
  ccache \
  cmake \
  font-adobe-100dpi \
  git-lite \
  jackit \
  libsndfile \
  lilv \
  libxkbcommon \
  pkgconf \
  pugixml \
  xcb \
  xorg \
  zita-resampler

cp ${MY_PATH}/.cshrc ~devel/.cshrc
chown devel:devel ~devel/.cshrc

if [ ! -d /usr/src/libmaolan ]; then
  git clone https://github.com/maolan/libmaolan /usr/src/libmaolan
  chown -R devel:devel /usr/src/libmaolan
fi

if [ ! -d /usr/src/maolan ]; then
  git clone https://github.com/maolan/maolan /usr/src/maolan
  chown -R devel:devel /usr/src/maolan
fi

if [ ! -d /usr/src/gnui ]; then
  git clone https://github.com/fisean/gnui /usr/src/gnui
  chown -R devel:devel /usr/src/gnui
fi

cat <<EOF >/etc/make.conf
WRKDIRPREFIX=/tmp
WITH_CCACHE_BUILD=YES
CCACHE_DIR=/usr/home/devel/.ccache
SU_CMD=/usr/local/bin/sudo -E sh -c
EOF
