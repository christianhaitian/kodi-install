#!/bin/bash

# Builds Kodi for GBM and select addons specifically targeting ArkOS

if [[ ! -z "${1}" ]]; then
  echo ""
else
  echo ""
  echo "Please provide the git-tag (such as 20.3-Nexus) of kodi you'd like to build"
  echo "Some possible values are as follows:"
  git ls-remote https://github.com/xbmc/xbmc.git --h --sort origin "refs/tags/*" | cut -d "/" -f3 | grep "Nexus\|Matrix"
  echo ""
  exit 1
fi

sed -i "/BRANCH\=/c\BRANCH\=$(echo ${1} | cut -d "-" -f2)" configuration.sh
sed -i "/KODI_SOURCE_TAG\=/c\KODI_SOURCE_TAG\=$(echo ${1})" configuration.sh
source configuration.sh
cd /home/kodi/

if [ -d "kodi-source" ]; then
  echo ""
  echo "You have a kodi-source folder already in existance."
  echo "If you type Y, this process will wipe the contents"
  echo "of this folder and download a fresh clone of the kodi"
  echo "git.  Continue? <Y/n>"
  echo ""
  read answer
  if [[ -z "$answer" ]] || [[ "$answer" == "Y" ]] || [[ "$answer" == "y" ]]; then
    echo "Continuing..."
  elif [[ "$answer" == "N" ]] || [[ "$answer" == "n" ]]; then
    echo ""
    echo "Stopping here since your typed $answer"
    echo ""
    exit 1
  else
    echo "I don't understand your answer.  Stopping here."
    echo ""
    exit 1
  fi

  rm -rf kodi-source
fi

if [[ -z $(git ls-remote https://github.com/xbmc/xbmc.git --h --sort origin "refs/tags/*" | cut -d "/" -f3 | grep -x "$KODI_SOURCE_TAG") ]]; then
  echo "Sorry, $KODI_SOURCE_TAG doesn't seem to exist in the kodi git"
  echo ""
  exit 1
fi
git clone https://github.com/xbmc/xbmc.git kodi-source
cd kodi-source
git checkout ${KODI_SOURCE_TAG}
if [ $? != 0 ]; then
  echo "Could not checkout the $BRANCH tag."
  echo ""
  exit 1
fi

# Creates build directory and configures Kodi build.

cd ../kodi-install
libmali/libmali.sh
if [ -d "/home/kodi/kodi-build" ]; then
  rm -rf /home/kodi/kodi-build/*
else
  mkdir -p /home/kodi/kodi-build
fi
cd ../kodi-source
for i in /home/kodi/kodi-install/patches/*.patch
do
    patch -Np1 < $i
    if [ $? != 0 ]; then
      echo "There was an issue applying patch $i.  Stopping here."
      echo ""
      exit 1
    fi
done

cd ../kodi-build
if [ -d "/home/kodi/bin-kodi" ]; then
  rm -rf /home/kodi/bin-kodi
fi
cmake ../kodi-source -DCMAKE_INSTALL_PREFIX=/home/kodi/bin-kodi -DENABLE_INTERNAL_FLATBUFFERS=ON -DENABLE_INTERNAL_DAV1D=ON -DCORE_PLATFORM_NAME=gbm -DAPP_RENDER_SYSTEM=gles
if [ $? != 0 ]; then
  echo ""
  echo "There was an issue with configuring the kodi source.  Stopping here."
  echo ""
  exit 1
fi
# Now build Kodi for ArkOS
num_proc=`nproc`
echo "Using $num_proc threads"
cmake --build . -- -j$num_proc
if [ $? != 0 ]; then
  echo ""
  echo "There was an issue with building the kodi source for the $BRANCH branch.  Stopping here."
  echo ""
  exit 1
fi
# Now build the Kodi addons for use in ArkOS

# Configure Kodi standard repository for binary addons.
repofname="${KODI_SOURCE_DIR}/cmake/addons/bootstrap/repositories/binary-addons.txt"
bin_addons_repo="binary-addons https://github.com/xbmc/repo-binary-addons.git $BRANCH"
rm -f $repofname
# -n no trailing newline
echo -n $bin_addons_repo >> $repofname
control_file="${KODI_SOURCE_DIR}/tools/depends/target/binary-addons/.installed-native"
echo "Control file ${control_file}"

# Build the addons
cd ${KODI_SOURCE_DIR}

if [ -d "/home/kodi/kodi-source/tools/depends/target/binary-addons/native/" ]; then
  rm -rf /home/kodi/kodi-source/tools/depends/target/binary-addons/native/
fi

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

# Finally, put everything in place so it can be copied into the ArkOS opt/kodi folder and overwrite the existing setup
cd /home/kodi
if [ -d "/home/kodi/ForArkOS" ]; then
  rm -rf /home/kodi/ForArkOS/*
fi

mkdir -p /home/kodi/ForArkOS/opt/kodi/lib/kodi/addons
mkdir -p /home/kodi/ForArkOS/opt/kodi/share/kodi/addons

# Let's strip and copy the kodi gbm executable
strip /home/kodi/kodi-build/kodi-gbm
cp -fv /home/kodi/kodi-build/kodi-gbm /home/kodi/ForArkOS/opt/kodi/lib/kodi/kodi-gbm
# Let's copy the necessary addons needed to successfylly launch kodi
cp -Rfv /home/kodi/kodi-build/addons/* /home/kodi/ForArkOS/opt/kodi/share/kodi/addons/.
# Let's copy the additional binary addons config files built 
cp -Rfv /home/kodi/bin-kodi/share/kodi/addons/* /home/kodi/ForArkOS/opt/kodi/share/kodi/addons/.
# Let's finally copy the additional binary addon libs
cp -Rfv /home/kodi/bin-kodi/lib/* /home/kodi/ForArkOS/opt/kodi/lib/.

echo ""
echo "Done! Check /home/kodi/ForArkOS and verify the kodi-gbm binary and addon files are in there and ready to be copied to ArkOS"
echo ""
