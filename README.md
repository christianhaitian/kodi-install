# Compile and install Kodi on Debian/Ubuntu distributions #

## Table of Contents

* **[Readme me first](#readme-me-first)**
* **[Cloning this repository](#cloning-this-repository)**
* **[Clone and prepare Kodi source code](#clone-and-prepare-kodi-source-code)**
* **[Compile and installing Kodi for the first time](#compile-and-installing-kodi-for-the-first-time)**
* **[Compiling the Kodi binary addons](#compiling-the-kodi-binary-addons)**
* **[Update Kodi](#update-kodi)**
* **[Notes](#notes)**

## Readme me first ##

These scripts assume that:

 * The build will happen in a aarch64 Ubuntu Bionic or Debian Buster based environment.
   * You can create a chroot to fullfil this need.  See [here](https://github.com/christianhaitian/arkos/wiki/Building#to-create-debian-based-chroots-in-a-linux-environment) for more info.  You can also download a preconfigured VM with these chroots already created [here](https://forum.odroid.com/viewtopic.php?p=306185#p306185).

 * The `/home/kodi` is the base folder during the configuration and build of kodi-gbm
 
 * The OS that the generated install will be used in Ubuntu 19.10 based.  Ubuntu 20.04 may work as well.
 
  * Kodi source code is located in `/home/kodi/kodi-source/`.
 
 * Kodi temporary build directory is `/home/kodi/kodi-build/`. You can safely
   delete it once Kodi has been compiled and installed.

 * Kodi will be installed in the directory `/home/kodi/bin-kodi/`.

 * Kodi user data directory is `~/.kodi/`.  As an example for ArkOS the user data directory will be `/home/ark/.kodi/`.

Once compiled and installed, you can execute Kodi by doing:
```
$ /home/kodi/bin-kodi/lib/kodi/kodi-gbm
```


To compile Kodi for ArkOS. This will take a while.
```
$ ./ArkOS-Kodi-Build.sh
```
The generate executable and addons will be located in the `/home/kodi/ForArkOS` directory.

The first time you execute Kodi the userdata directory `/home/ark/.kodi/` will be created.

Now that Kodi is installed you can safely delete the Kodi build directory to save disk space:
```
$ ./purge-build-directory.sh
```

Do not purge the build directory before compiling the binary addons.


the binary addons are automatically installed in `/home/kodi/bin-kodi/` after compilation.


## Update Kodi ##

Update Kodi source code:
```
$ cd /home/kodi-source/
$ git checkout master
$ git pull
```

If you wish to set a specific version:
```
$ git checkout 17.6-Krypton
```

Then configure, compile and install Kodi again:
```
$ cd /home/kodi/kodi-install/
$ ./configure-kodi.sh
$ ./build-kodi-gbm.sh
$ ./install-kodi.sh
$ ./build-binary-addons-arkos.sh
```

If you plan to update Kodi frequently then do not execute `purge-build-directory.sh` to save
compilation time (only files changed will be recompiled).


## Notes ##

 * Compiling the binary addons with `build-binary-addons-no-pvr.sh` installs them in
   `/home/kodi/bin-kodi/` even if Kodi has not been installed before.

 * The addons `game.controller.*` are not binary addons. They can be downloaded with the Kodi
   addon manager.

 * Kodi is built out-of-source but the binary addons are build inside the Kodi source.

 * Executing `build-binary-addons-no-pvr.sh` or `build-binary-addons-libretro-cores.sh`
   updates the binary addons source code if it has been changed?

 * After a fresh installation all the binary addons are **disabled**. They must be enabled
   in `Settings` -> `Addons` -> `My addons`.

 * If a Libretro core is not installed the extensions it supports are not shown in the
   Games source filesystem browser. Libretro core addons must installed/enabled first.
