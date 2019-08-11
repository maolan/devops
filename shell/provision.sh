#!/bin/sh

MY_PATH=`dirname $0`

pkg install -y ccache xorg font-adobe-100dpi git-lite autoconf libsndfile pugixml zita-resampler
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
