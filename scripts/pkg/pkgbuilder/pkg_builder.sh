#!/bin/bash

BUNDLEID=''
VERSION='1'
LOCATION='/Applications'
BUNDLE_IS_RELOCATABLE='0'
DEVELOPER_ID_INSTALLER=''

if [ -z "$BUNDLEID" ] || [ -z "$VERSION" ];then
    echo "Please, use the use at least this scripts arguments:"
    echo "BUNDLEID (com.app...) VERSION (pkg version)"
    exit
else
    # Get the absolute path of the directory containing this script
    DIR=$(unset CDPATH && cd "$(dirname "$0")" && echo $PWD)
    BUILD=$(date +%Y%m%d%H%M)

    # Every use should have read rights and scripts should be executable
    /bin/chmod -R o+r "$DIR/payload/"
    /bin/chmod +x "$DIR/scripts/"

    #turns preinstall and postinstall files into executables if they exist
    if [ -e "$DIR/scripts/preinstall" ];then
        chmod a+x "$DIR/scripts/preinstall"
    fi

    if [ -e "$DIR/scripts/postinstall" ];then
        chmod a+x "$DIR/scripts/postinstall"
    fi

    #clear the .files  from the folders
    /usr/bin/find "$DIR" -name .DS_Store -delete
    /usr/bin/find "$DIR/payload/" -name .DS_Store -delete
    /usr/bin/find "$DIR/payload/" -name .keep -delete
    /usr/bin/find "$DIR/scripts/" -name .DS_Store -delete
    /usr/bin/find "$DIR/scripts/" -name .keep -delete

    #Validations
    if [ ! "$(ls -A $DIR/payload/)" ];then

        if [ ! -e "$DIR/scripts/postinstall" ] || [ ! -e "$DIR/scripts/postinstall" ];then

            echo "The package must contain at least one script"
            exit
        fi

    else

        if [ -z "$LOCATION" ] ;then

            echo "If there is a payload there must be an installation location"
            echo "Please, use the use at least this scripts arguments:"
            echo "BUNDLEID (com.app...) VERSION (pkg version) LOCATION (/Applications/ for example)"
            exit
        fi

        if [ -z $BUNDLE_IS_RELOCATABLE ] ;then

            echo "If there is a payload the parameter BUNDLE_IS_RELOCATABLE has to be defined"
            echo "Please, use the use at least this scripts arguments:"
            echo "BUNDLEID (com.app...) VERSION (pkg version) LOCATION (/Applications/ for example) BUNDLE_IS_RELOCATABLE (1 or 0)"
            exit
        fi

    fi

    COMMAND="pkgbuild --identifier $BUNDLEID"

    if [ ! -z "$DEVELOPER_ID_INSTALLER" ];then
        COMMAND+=" --sign Developer ID Installer: $DEVELOPER_ID_INSTALLER"
    fi

    if [ ! "$(ls -A $DIR/payload/)" ];then
        COMMAND+=" --nopayload"
    else

        if [ ! -z $BUNDLE_IS_RELOCATABLE ] && [ $BUNDLE_IS_RELOCATABLE -eq 0 ];then
            pkgbuild --analyze --root "$DIR/payload/" "$DIR/Info.plist"
            plutil -replace BundleIsRelocatable -bool NO "$DIR/Info.plist"
            COMMAND+=" --component-plist $DIR/Info.plist"
        fi

        COMMAND+=" --root $DIR/payload/ --install-location $LOCATION"

    fi

    if [ -e "$DIR/scripts/postinstall" ] || [ -e "$DIR/scripts/postinstall" ];then
        COMMAND+=" --scripts $DIR/scripts/"
    fi
                
    COMMAND+=" --version $VERSION $DIR/$BUNDLEID-$BUILD.pkg"

    eval $COMMAND

    if [ ! -z $BUNDLE_IS_RELOCATABLE ] && [ $BUNDLE_IS_RELOCATABLE -eq 0 ];then
        rm "$DIR/Info.plist"
    fi
fi