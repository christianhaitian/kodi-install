#!/bin/bash

# Builds Kodi for GBM and select addons specifically targeting ArkOS

if [[ ! -z "${1}" ]]; then
  echo ""
else
  echo ""
  echo "Please provide the git-tag (such as 20.3-Nexus) of kodi you'd like to build"
  echo "Some possible values are as follows:"
  git ls-remote https://github.com/xbmc/xbmc.git --h --sort origin "refs/tags/*" | cut -d "/" -f3 | grep "Nexus\|Matrix\|Omega"
  echo ""
  exit 1
fi

sed -i "/BRANCH\=/c\BRANCH\=$(echo ${1} | cut -d "-" -f2)" configuration.sh
sed -i "/KODI_SOURCE_TAG\=/c\KODI_SOURCE_TAG\=$(echo ${1})" configuration.sh
source configuration.sh
if [ ! -d "/home/ark/kodi" ]; then
  mkdir /home/ark/kodi/
fi
cd /home/ark/kodi/

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
if [ -d "/home/ark/kodi/kodi-build" ]; then
  rm -rf /home/ark/kodi/kodi-build/*
else
  mkdir -p /home/ark/kodi/kodi-build
fi
cd ../kodi-source
for i in /home/ark/kodi/kodi-install/patches/*.patch
do
    patch -Np1 < $i
    if [ $? != 0 ]; then
      echo "There was an issue applying patch $i.  Stopping here."
      echo ""
      exit 1
    fi
done

cd ../kodi-build
if [ -d "/home/ark/kodi/bin-kodi" ]; then
  rm -rf /home/ark/kodi/bin-kodi
fi
cmake ../kodi-source -DCMAKE_INSTALL_PREFIX=/home/ark/kodi/bin-kodi -DCORE_PLATFORM_NAME=gbm -DAPP_RENDER_SYSTEM=gles
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
#cmake --build . --
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

if [ -d "/home/ark/kodi/kodi-source/tools/depends/target/binary-addons/native/" ]; then
  rm -rf /home/ark/kodi/kodi-source/tools/depends/target/binary-addons/native/
fi

rm -f /home/ark/kodi/kodi-source/tools/depends/target/binary-addons/.installed-native
make -j$num_proc -C tools/depends/target/binary-addons PREFIX=/home/ark/kodi/bin-kodi ADDONS="audiodecoder.* audioencoder.* inputstream.* peripheral.* pvr.* vfs.* visualization.*"

# inputstream.adaptive has to be built separately because it fails to build due to an issue with widevine support code
#cd ..
#if [ -d "inputstream.adaptive" ]; then
  #rm -rf inputstream.adaptive
#fi
#git clone --branch $BRANCH https://github.com/xbmc/inputstream.adaptive.git
#mkdir inputstream.adaptive/build
#cd inputstream.adaptive/build
#cmake -DADDONS_TO_BUILD=inputstream.adaptive -DADDON_SRC_PREFIX=../.. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/home/ark/kodi/bin-kodi/ -DPACKAGE_ZIP=1 /home/ark/kodi/kodi-source/cmake/addons/
# This sed of inputstream is needed or it won't build for some reason.
#if [[ "$BRANCH" == "Nexus" ]]; then
  #sed -i -e '/if defined(__linux__) && defined(__aarch64__) && !defined(ANDROID)/,+12d' ../wvdecrypter/wvdecrypter.cpp
#elif [[ "$BRANCH" == "Omega" ]]; then
  #sed -i -e '/if defined(__linux__) && (defined(__aarch64__) || defined(__arm64__))/,+13d' ../lib/cdm_aarch64/cdm_loader.cpp
#fi
#make -j$num_proc
#mkdir /home/ark/kodi/bin-kodi/lib/kodi/addons/inputstream.adaptive
#mv -f /home/ark/kodi/bin-kodi/inputstream.adaptive/inputstream.adaptive.so* /home/ark/kodi/bin-kodi/lib/kodi/addons/inputstream.adaptive/.
#mv -f /home/ark/kodi/bin-kodi/inputstream.adaptive/libssd_wv.so /home/ark/kodi/bin-kodi/lib/kodi/addons/inputstream.adaptive/.
#mkdir /home/ark/kodi/bin-kodi/share/kodi/addons/inputstream.adaptive
#mv -f /home/ark/kodi/bin-kodi/inputstream.adaptive/* /home/ark/kodi/bin-kodi/share/kodi/addons/inputstream.adaptive/.

# inputstream.ffmpegdirect has to be built separately because it fails to build due to some nettle library nonsense
# I don't currently understand or care to try to figure out at the moment
cd ..
if [ -d "inputstream.ffmpegdirect" ]; then
  rm -rf inputstream.ffmpegdirect
fi
git clone --branch $BRANCH https://github.com/xbmc/inputstream.ffmpegdirect.git
#wget https://patch-diff.githubusercontent.com/raw/xbmc/inputstream.ffmpegdirect/pull/297.patch -O inputstream.ffmpegdirect/depends/common/libzvbi/0010-fix-building-without-README.patch
mkdir inputstream.ffmpegdirect/build
cd inputstream.ffmpegdirect
#patch -Np1 < ../kodi-install/patches/inputstream-ffmpegdirect/inputstream-ffmpegdirect.patch
cd build
cmake -DADDONS_TO_BUILD=inputstream.ffmpegdirect -DADDON_SRC_PREFIX=../.. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/home/ark/kodi/bin-kodi/ -DPACKAGE_ZIP=1 /home/ark/kodi/kodi-source/cmake/addons/
make -j$num_proc
ERROR=$(echo $?)
if [[ $ERROR != "0" ]]; then
  printf "hmmm...building the ffmpegdirect inputstream addon failed.  Let's try a sed trick to see if that solves the issue"
  sleep 5
  sed -i "/AM_INIT_AUTOMAKE(\[1.16 check-news dist-bzip2\])/c\AM_INIT_AUTOMAKE(\[1.16 check-news dist-bzip2 foreign\])" build/libzvbi/src/libzvbi/configure.ac
  make -j$num_proc
fi
if [[ $ERROR == "0" ]]; then
  echo "Yay, ffmpegdirect addon built successfully!"
  mkdir /home/ark/kodi/bin-kodi/lib/kodi/addons/inputstream.ffmpegdirect
  mv -f /home/ark/kodi/bin-kodi/inputstream.ffmpegdirect/inputstream.ffmpegdirect.so* /home/ark/kodi/bin-kodi/lib/kodi/addons/inputstream.ffmpegdirect/.
  mkdir /home/ark/kodi/bin-kodi/share/kodi/addons/inputstream.ffmpegdirect
  mv -f /home/ark/kodi/bin-kodi/inputstream.ffmpegdirect/* /home/ark/kodi/bin-kodi/share/kodi/addons/inputstream.ffmpegdirect/.
else
  echo ""
  echo "Boo! ffmpegdirect build failed :("
  echo ""
fi

# Finally, put everything in place so it can be copied into the ArkOS opt/kodi folder and overwrite the existing setup
cd /home/ark/kodi
if [ -d "/home/ark/kodi/ForArkOS" ]; then
  rm -rf /home/ark/kodi/ForArkOS/*
fi

mkdir -p /opt/kodi/lib/kodi/addons
mkdir -p /opt/kodi/share/kodi/addons

# Let's strip and copy the kodi gbm executable
strip /home/ark/kodi/kodi-build/kodi-gbm
cp -fv /home/ark/kodi/kodi-build/kodi-gbm /opt/kodi/lib/kodi/kodi-gbm
# Let's copy the necessary addons needed to successfully launch kodi
cp -Rfv /home/ark/kodi/kodi-build/addons/* /opt/kodi/share/kodi/addons/.
cp -Rfv /home/ark/kodi/kodi-build/media/ /opt/kodi/share/kodi/.
cp -Rfv /home/ark/kodi/kodi-build/system/ /opt/kodi/share/kodi/.
# Let's copy the additional binary addons config files built 
cp -Rfv /home/ark/kodi/bin-kodi/share/kodi/addons/* /opt/kodi/share/kodi/addons/.
# Let's finally copy the additional binary addon libs
cp -Rfv /home/ark/kodi/bin-kodi/lib/* /opt/kodi/lib/.
# As an added benefit, create the .xz file for ease of updating ArkOS
#cd /home/ark/kodi/ForArkOS
#VER_NUM=$(echo $KODI_SOURCE_TAG | sed 's/\-.*//')
#tar -cJvf ../Kodi-${VER_NUM}.tar.xz *
#cd /home/ark/kodi
echo ""
echo "Done!"
echo ""
