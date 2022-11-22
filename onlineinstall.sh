#!/bin/bash

set -eu
trap 'echo "Script failed with exit code $?."' EXIT

macos_install() {
echo -e "\nDetecting processor architecture..."
arch_name=$(uname -m)
if [ "${arch_name}" = "x86_64" ]; then
    if [ "$(sysctl -in sysctl.proc_translated)" = "1" ]; then
        echo "Running on Rosetta 2"
        echo "No native support for arm64 yet, will use Rosetta 2"
        #ARCH="arm64"
        ARCH="x64"
    else
        echo "Running on native Intel"
        ARCH="x64"
    fi 
elif [ "${arch_name}" = "arm64" ]; then
    echo "Running on M1"
    echo "No native support for arm64 yet, will need Rosetta 2"
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

echo -e "\nSelect installation directory:"
# open folder picking dialog, set path to Desktop if fails
TARGETPATH="$(osascript -l JavaScript -e 'a=Application.currentApplication();a.includeStandardAdditions=true;a.chooseFolder({withPrompt:"Select installation directory:"}).toString()')" || { echo "Failed to select directory, setting to Desktop"; TARGETPATH="/Users/$(whoami)/Desktop"; }
# Add trailing slash if not present
if [ "${TARGETPATH: -1}" != "/" ]; then
    TARGETPATH="$TARGETPATH/"
fi
echo "Selected installation path: $TARGETPATH"

while true; do
    read -p "Do you want to install the Loader to the selected directory? (y/n) " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) echo "Installation cancelled."; exit;;
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
curl --fail -L "https://github.com/skrimix/QLoaderFiles/releases/latest/download/osx-$ARCH.zip" -o "/tmp/osx-$ARCH.zip"
echo "Download complete"

echo "Installing"
if [ -d /tmp/osx-$ARCH ]; then
    rm -rf /tmp/osx-$ARCH
fi
unzip -q "/tmp/osx-$ARCH.zip" -d /tmp/osx-$ARCH
rm "/tmp/osx-$ARCH.zip"
cp -rf "/tmp/osx-$ARCH/." "${TARGETPATH}Loader/"
rm -r "/tmp/osx-$ARCH"

if [ "$TRAILERS" = "1" ]; then
    echo "Downloading trailers add-on..."
    curl --fail -L "https://github.com/skrimix/QLoaderFiles/releases/latest/download/TrailersAddon.zip" -o "/tmp/TrailersAddon.zip"
    echo "Download complete"
    echo "Copying trailers add-on to installation directory. Loader will install it on first start."
    mv -f "/tmp/TrailersAddon.zip" "${TARGETPATH}Loader/TrailersAddon.zip"
fi

# Just in case
echo "Removing quarantine attrs"
xattr -rd com.apple.quarantine "${TARGETPATH}Loader/"

echo -e "\nInstallation completed\nLoader has been installed to ${TARGETPATH}Loader/"
echo -e "You can start it by double-clicking the Loader executable in Finder.\n"
}

linux_install() {
echo -e "\nDetecting processor architecture..."
arch_name=$(uname -m)
if [ "${arch_name}" = "x86_64" ]; then
    if [ "$(getconf LONG_BIT)" == "32" ]; then
        echo "You are running x86 Linux"
        echo "Loader only supports x64 and arm64 Linux"
        exit 1
    fi
    echo "Running on x64"
    ARCH="x64"
elif [ "${arch_name}" = "arm64" ]; then
    echo "Running on arm64"
    ARCH="arm64"
else
    echo "Unknown architecture: ${arch_name}"
    exit 1
fi

echo -e "\nEnter installation directory path or leave empty to install to current directory:"
read TARGETPATH
if [ -z "$TARGETPATH" ]; then
    TARGETPATH=$(pwd)
fi
# Check if directory exists
if [ ! -d "$TARGETPATH" ]; then
    echo "Directory $TARGETPATH does not exist"
    exit 1
fi
# Add trailing slash if not present
if [ "${TARGETPATH: -1}" != "/" ]; then
    TARGETPATH="$TARGETPATH/"
fi

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

echo -e "\nDownloading latest release for Linux ${ARCH}..."
curl --fail -L "https://github.com/skrimix/QLoaderFiles/releases/latest/download/linux-$ARCH.tar.gz" -o /tmp/linux-$ARCH.tar.gz
echo "Download complete"

echo "Installing"
if [ -d /tmp/linux-$ARCH ]; then
    rm -rf /tmp/linux-$ARCH
fi
tar xf "/tmp/linux-$ARCH.tar.gz" -C /tmp
rm "/tmp/linux-$ARCH.tar.gz"
cp -rf "/tmp/linux-$ARCH/." "${TARGETPATH}Loader/"
rm -r "/tmp/linux-$ARCH"

if [ "$TRAILERS" = "1" ]; then
    echo "Downloading trailers add-on..."
    curl --fail -L "https://github.com/skrimix/QLoaderFiles/releases/latest/download/TrailersAddon.zip" -o /tmp/TrailersAddon.zip
    echo "Download complete"
    echo "Copying trailers add-on to installation directory. Loader will install it on first start."
    mv -f "/tmp/TrailersAddon.zip" "${TARGETPATH}Loader/TrailersAddon.zip"

    echo "NOTE: You need to have VLC player installed to use trailers add-on."
    # If we are running on Arch, show message with it's package names
    if [ -f /etc/pacman.conf ]; then
        echo "You may also need to install libx11 (from extra repository) and libvlc (from AUR)"
    # Else show message with debian package names
    else
        echo "You may also need to install libx11-dev and libvlc-dev packages."
    fi
fi

while true; do
    read -p "Do you want to create a desktop entry? (y/n) " yn
    case $yn in
        [Yy]* ) CREATESHORTCUT=1;break;;
        [Nn]* ) CREATESHORTCUT=0;break;;
        * ) echo "Please answer yes or no.";;
    esac
done

if [ "$CREATESHORTCUT" = "1" ]; then
    echo "Creating desktop entry..."
    if [ ! -d ~/.local/share/applications ]; then
        mkdir -p ~/.local/share/applications
    fi
    cat > ~/.local/share/applications/com.ffa.qloader.desktop <<EOL
[Desktop Entry]
Name=QLoader
Comment=Launch QLoader
Exec=${TARGETPATH}Loader/Loader
Icon=${TARGETPATH}Loader/Loader.png
Terminal=true
Type=Application
Categories=Game;
Path=${TARGETPATH}Loader/
EOL
chmod +x ~/.local/share/applications/com.ffa.qloader.desktop
echo "Desktop entry created"
fi

echo -e "\nInstallation completed\nLoader has been installed to ${TARGETPATH}Loader/"
echo -e "You can start it with the following command:\n${TARGETPATH}Loader/Loader\n"
}



echo "Welcome to Loader online installer"

echo -e "\nDetecting OS..."
if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "Running on macOS"
        macos_install
elif [[ "$OSTYPE" == "linux-gnu" ]]; then
        echo "Running on Linux"
        linux_install
else
        echo "Your OS is not supported, sorry!"
        echo "Exiting..."
        exit 1
fi

trap : EXIT
