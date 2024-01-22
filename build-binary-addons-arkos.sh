#!/bin/bash

# Builds Kodi binary addons except PVR addons.
# Uses Kodi standard repository for binary addons.
source configuration.sh

# Configure Kodi standard repository for binary addons.
repofname="${KODI_SOURCE_DIR}/cmake/addons/bootstrap/repositories/binary-addons.txt"
bin_addons_repo="binary-addons https://github.com/xbmc/repo-binary-addons.git $BRANCH"
rm -f $repofname
# -n no trailing newline
echo -n $bin_addons_repo >> $repofname
control_file="${KODI_SOURCE_DIR}/tools/depends/target/binary-addons/.installed-native"
echo "Control file ${control_file}"

# Build the addons
num_proc=`nproc`
echo "Using $num_proc processors"
cd ${KODI_SOURCE_DIR}

rm -f /home/kodi/kodi-source/tools/depends/target/binary-addons/.installed-native
make -j$num_proc -C tools/depends/target/binary-addons PREFIX=/home/kodi/bin-kodi ADDONS="audiodecoder.* audioencoder.* inputstream.* peripheral.* pvr.* vfs.* visualization.*"

# inputstream.adaptive has to be built separately because it fails to build due to an issue with widevine support code
cd ..
if [ -d "inputstream.adaptive" ]; then
  rm -rf inputstream.adaptive
fi
git clone --branch $BRANCH https://github.com/xbmc/inputstream.adaptive.git
mkdir inputstream.adaptive/build
cd inputstream.adaptive/build
cmake -DADDONS_TO_BUILD=inputstream.adaptive -DADDON_SRC_PREFIX=../.. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/home/kodi/bin-kodi/ -DPACKAGE_ZIP=1 /home/kodi/kodi-source/cmake/addons/
# This sed of inputstream is needed or it won't build for some reason.
sed -i -e '/if defined(__linux__) && defined(__aarch64__) && !defined(ANDROID)/,+12d' ../wvdecrypter/wvdecrypter.cpp
make -j5
mkdir /home/kodi/bin-kodi/lib/kodi/addons/inputstream.adaptive
mv -f /home/kodi/bin-kodi/inputstream.adaptive/inputstream.adaptive.so* /home/kodi/bin-kodi/lib/kodi/addons/inputstream.adaptive/.
mv -f /home/kodi/bin-kodi/inputstream.adaptive/libssd_wv.so /home/kodi/bin-kodi/lib/kodi/addons/inputstream.adaptive/.
mkdir /home/kodi/bin-kodi/share/kodi/addons/inputstream.adaptive
mv -f /home/kodi/bin-kodi/inputstream.adaptive/* /home/kodi/bin-kodi/share/kodi/addons/inputstream.adaptive/.

