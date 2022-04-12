#!/bin/bash

set -eu
trap 'echo "Script failed with exit code $?."' EXIT

macos_install() {
echo -e "\nDetecting processor architecture..."
arch_name=$(uname -m)
if [ "${arch_name}" = "x86_64" ]; then
    if [ "$(sysctl -in sysctl.proc_translated)" = "1" ]; then
        echo "Running on Rosetta 2"
        ARCH="arm64"
    else
        echo "Running on native Intel"
        ARCH="x64"
    fi 
elif [ "${arch_name}" = "arm64" ]; then
    echo "Running on M1"
    #ARCH="arm64"
    ARCH="x64"
else
    echo "Unknown architecture: ${arch_name}"
    exit 1
fi

#if [ "$ARCH" = "arm64" ]; then
#while true; do
#    read -p "Do you want to install the native M1 version of the Loader? (y/n) " yn
#    case $yn in
#        [Yy]* ) break;;
#        [Nn]* ) ARCH="x64"; break;;
#        * ) echo "Please answer yes or no.";;
#    esac
#done
#fi
echo "Using $ARCH architecture"

echo -e "\nPlease select installation directory:"
TARGETPATH="$(osascript -l JavaScript -e 'a=Application.currentApplication();a.includeStandardAdditions=true;a.chooseFolder({withPrompt:"Please select installation directory:"}).toString()')"
echo "Selected installation path: $TARGETPATH"

while true; do
    read -p "Do you want to install the Loader to the selected directory? (y/n) " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

while true; do
    read -p "Do you want to install optional trailers add-on (~1GB)? (y/n) " yn
    case $yn in
        [Yy]* ) TRAILERS=1;break;;
        [Nn]* ) TRAILERS=0;break;;
        * ) echo "Please answer yes or no.";;
    esac
done


echo -e "\nDownloading latest release for macOS ${ARCH}..."
curl --fail -L -O "https://github.com/skrimix/QLoaderFiles/releases/latest/download/osx-$ARCH.zip"
echo "Download complete"

echo "Installing"
if [ -d osx-$ARCH ]; then
    rm -rf osx-$ARCH
fi
unzip -q "osx-$ARCH.zip"
rm "osx-$ARCH.zip"
cp -rf "osx-$ARCH/" "$TARGETPATH/Loader/"
rm -r "osx-$ARCH"

if [ "$TRAILERS" = "1" ]; then
    echo "Downloading trailers add-on..."
    curl --fail -L -O "https://github.com/skrimix/QLoaderFiles/releases/latest/download/TrailersAddon.zip"
    echo "Download complete"
    echo "Copying trailers add-on to installation directory. Loader will install it on first start."
    mv -f "TrailersAddon.zip" "$TARGETPATH/Loader/TrailersAddon.zip"
fi

# Just in case
echo "Removing quarantine attrs"
xattr -rd com.apple.quarantine "$TARGETPATH/Loader/"

echo -e "\nInstallation completed\nNow you can run the Loader from $TARGETPATH/Loader/"
}

linux_install() {
if [ "$(getconf LONGBIT)" != "64" ]; then
    echo "You are running x86 Linux"
    echo "Loader only supports x64 Linux"
    exit 1
fi

echo -e "\nPlease enter installation directory path:"
read TARGETPATH
# Check if directory exists
if [ ! -d "$TARGETPATH" ]; then
    echo "Directory $TARGETPATH does not exist"
    exit 1
fi

while true; do
    read -p "Do you want to install the Loader to the selected directory? (y/n) " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

while true; do
    read -p "Do you want to install optional trailers add-on (~1GB)? (y/n) " yn
    case $yn in
        [Yy]* ) TRAILERS=1;break;;
        [Nn]* ) TRAILERS=0;break;;
        * ) echo "Please answer yes or no.";;
    esac
done

echo -e "\nDownloading latest release for Linux x64..."
curl --fail -L -O "https://github.com/skrimix/QLoaderFiles/releases/latest/download/linux-x64.zip"
echo "Download complete"

echo "Installing"
if [ -d linux-x64 ]; then
    rm -rf linux-x64
fi
unzip -q "linux-x64.zip"
rm "linux-x64.zip"
cp -rf "linux-x64/" "$TARGETPATH/Loader/"
rm -r "linux-x64"

if [ "$TRAILERS" = "1" ]; then
    echo "Downloading trailers add-on..."
    curl --fail -L -O "https://github.com/skrimix/QLoaderFiles/releases/latest/download/TrailersAddon.zip"
    echo "Download complete"
    echo "Copying trailers add-on to installation directory. Loader will install it on first start."
    mv -f "TrailersAddon.zip" "$TARGETPATH/Loader/TrailersAddon.zip"

    echo "NOTE: You need to have VLC player installed to use trailers add-on."
    # If we are running on Arch, show message with it's package names
    if [ -f /etc/pacman.conf ]; then
        echo "You may also need to install libx11 (from extra repository) and libvlc (from AUR)"
    # Else show message with debian package names
    else
        echo "You may also need to install libx11-dev and libvlc-dev packages."
    fi
fi

echo -e "\nInstallation completed\nNow you can run the Loader from $TARGETPATH/Loader/"
}



echo "Welcome to Loader online installer"

echo -e "\nDetecting OS..."
if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "Running on macOS"
        macos_install
elif [[ "$OSTYPE" == "linux-gnu" ]]; then
        linux_install
else
        echo "Your OS is not supported, sorry!"
        echo "Exiting..."
        exit 1
fi

trap : EXIT
