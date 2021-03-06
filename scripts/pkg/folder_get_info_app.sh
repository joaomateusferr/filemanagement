#!/bin/bash

#Developer notes
#The command "pkgutil --expand-full" uses macos environment variables to work so please run this script in Terminal app
#Use the "pwd" command to get the folder path because it must contain the entire path

FOLDER='/Users/joaoferreira/Downloads'
FOLDER_TO_EXTRACT_TO='/private/tmp/extracted_pkg'

FULL_PKG_COUNT=0

for FULL_PKG in $FOLDER/*.pkg; do

    if [ "$FULL_PKG" == "$FOLDER/*.pkg" ];then   #the $FULL_PKG variable will be $FOLDER/*.pkg when there is no .pkg inside the folder
        break
    fi

    echo '-----------------------------------------'
    echo $(basename $FULL_PKG)

    PATH_TO_PKG=${FULL_PKG// /\\ }

    APP_COUNT=0

    if [ -e "$FOLDER_TO_EXTRACT_TO" ];then
        rm -rf "$FOLDER_TO_EXTRACT_TO"
    fi

    eval pkgutil --expand-full $PATH_TO_PKG $FOLDER_TO_EXTRACT_TO > /dev/null 2>&1 

    if [ $? -eq 0 ];then

        cd $FOLDER_TO_EXTRACT_TO

        PKG_FILE=$(ls | grep '\.pkg$' | head -1)

        if [ -z "$PKG_FILE" ];then
            rm -rf "$FOLDER_TO_EXTRACT_TO"
            echo 'No internal .pkg file found in the package ignoring...'
        else
            for PKG in $FOLDER_TO_EXTRACT_TO/*.pkg; do
                    
                PKG_PATH=${PKG// /\\ }

                if [ ! -e "$PKG_PATH/Payload" ];then #ignoring pkgs without payload
                    continue
                fi

                eval "cd $PKG_PATH/Payload"

                if [ -e "Applications/" ];then
                    cd Applications
                fi

                for APP in *.app; do

                    if [ "$APP" == "*.app" ];then   #the $APP variable will be *.app when there is no .app inside the internal package
                        break
                    fi
                        
                    APP_PATH=${APP// /\\ }
                    eval "cd $APP_PATH"
                        
                    APP_DIR=$(pwd)
                    APP_DIR_PATH=${APP_DIR// /\\ }
                        
                    APP_NAME=$APP
                    APP_BUNDLE=$(eval "defaults read $APP_DIR_PATH/Contents/Info.plist CFBundleIdentifier")
                    APP_VERSION=$(eval "defaults read $APP_DIR_PATH/Contents/Info.plist CFBundleShortVersionString")

                    echo ''    
                    echo 'App Info: '
                    echo "Name: $APP_NAME"
                    echo "Bundle: $APP_BUNDLE"
                    echo "Version: $APP_VERSION"
                    echo ''
                    APP_COUNT=$(( $APP_COUNT + 1 )) 
                    cd ..
                done

                if [ -e "Applications" ];then
                    cd ..
                fi

                cd ..
            done
            cd ..
            cd ..
            rm -rf "$FOLDER_TO_EXTRACT_TO"

            if [ $APP_COUNT -eq 0 ];then
                echo 'No .app file found in the package'
            fi
        fi
    else
        echo 'Error when trying to unpack the package'
    fi

    echo '-----------------------------------------'

    FULL_PKG_COUNT=$(( $FULL_PKG_COUNT + 1 ))

done

if [ $FULL_PKG_COUNT -eq 0 ];then
    echo 'No .pkg file found in the folder'
fi