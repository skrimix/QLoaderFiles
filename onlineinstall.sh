#!/bin/bash

set -eu
trap 'echo "Script failed with exit code $?."' EXIT

macos_installation() {
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

echo -e "\nDownloading latest release for ${ARCH}..."
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

# Just in case
echo "Removing quarantine attrs"
xattr -rd com.apple.quarantine "$TARGETPATH/Loader/"

echo -e "Installation completed\nNow you can run the Loader from $TARGETPATH/Loader/"
}

linux_installation() {
echo "Linux is not supported by this script yet, sorry!"
echo "Please use manual installation instructions"
echo "Exiting..."
exit 1
}



echo "Welcome to Loader online installer"

echo -e "\nDetecting OS..."
if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "Running on macOS"
        macos_installation
elif [[ "$OSTYPE" == "linux-gnu" ]]; then
        linux_installation
else
        echo "Your OS is not supported, sorry!"
        echo "Exiting..."
        exit 1
fi

trap : EXIT
