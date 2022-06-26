#!/bin/bash

# Creates build directory and configures Kodi build.

libmali/libmali.sh
mkdir -p /home/kodi/kodi-build
cd ../kodi-source

for i in /home/kodi/kodi-install/patches/*.patch
do 
    patch -Np1 < $i
done

cd /home/kodi/kodi-build

# Options: -DVERBOSE=ON

cmake ../kodi-source -DCMAKE_INSTALL_PREFIX=/home/kodi/bin-kodi -DENABLE_INTERNAL_FLATBUFFERS=ON -DENABLE_INTERNAL_DAV1D=ON -DCORE_PLATFORM_NAME=gbm -DAPP_RENDER_SYSTEM=gles

