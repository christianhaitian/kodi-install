#!/bin/bash

# Creates build directory and configures Kodi build.

mkdir -p /home/kodi/kodi-build
cd ../kodi-source
patch -Np1 < ../kodi-install/patches/*.patch
cd /home/kodi/kodi-build

# Options: -DVERBOSE=ON

cmake ../kodi-source -DCMAKE_INSTALL_PREFIX=/home/kodi/bin-kodi -DENABLE_INTERNAL_FLATBUFFERS=ON -DCORE_PLATFORM_NAME=gbm -DAPP_RENDER_SYSTEM=gles

