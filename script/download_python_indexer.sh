#!/bin/bash

SOURCETRAIL_PYTHON_INDEXER_VERSION="v1_db25_p0"

# Determine current platform
PLATFORM='unknown'
if [ "$(uname)" == "Darwin" ]; then
	PLATFORM='osx'
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
	PLATFORM='linux'
elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW32_NT" ]; then
	PLATFORM='windows'
elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ]; then
	PLATFORM='windows'
elif [ "$OSTYPE" == "msys" ]; then
	PLATFORM='windows'
fi

PACKAGE_NAME="SourcetrailPythonIndexer_${SOURCETRAIL_PYTHON_INDEXER_VERSION}-${PLATFORM}"
PACKAGE_FILE_NAME="${PACKAGE_NAME}.zip"
PACKAGE_URL="https://github.com/CoatiSoftware/SourcetrailPythonIndexer/releases/download/${SOURCETRAIL_PYTHON_INDEXER_VERSION}/${PACKAGE_FILE_NAME}"
TEMP_PATH="build\\temp"
TARGET_PATH="bin\\app\\data\\python"


ABORT="\033[31mAbort:\033[00m"
SUCCESS="\033[32mSuccess:\033[00m"
INFO="\033[33mInfo:\033[00m"

if [ $PLATFORM == "windows" ]; then
	ORIGINAL_PATH_TO_SCRIPT="${0}"
	echo "ORIGINAL_PATH_TO_SCRIPT: $ORIGINAL_PATH_TO_SCRIPT"
	CLEANED_PATH_TO_SCRIPT="${ORIGINAL_PATH_TO_SCRIPT//\\//}"
	echo "CLEANED_PATH_TO_SCRIPT: $CLEANED_PATH_TO_SCRIPT"
	ROOT_DIR=${CLEANED_PATH_TO_SCRIPT%/*}
	echo "ROOT_DIR: $ROOT_DIR"
else
	ROOT_DIR="$( cd "$( dirname "$0" )" && pwd )"
fi

ROOT_DIR=$ROOT_DIR/..

# Enter main directory
cd $ROOT_DIR/


if [ -e "$TARGET_PATH/SourcetrailPythonIndexer.exe" ]; then
    echo "SourcetrailPythonIndexer already exists, checking version..."
	
	INSTALLED_VERSION="$($TARGET_PATH/SourcetrailPythonIndexer.exe --version)"
	INSTALLED_VERSION="$(sed -e 's#.* \(\)#\1#' <<< $INSTALLED_VERSION)"
	echo "SourcetrailPythonIndexer version is: $INSTALLED_VERSION"
	
	INSTALLED_VERSION="$(echo $INSTALLED_VERSION | tr . _)"
	
	if [ $INSTALLED_VERSION == $SOURCETRAIL_PYTHON_INDEXER_VERSION ]; then
		echo "Nothing to update. Target version of SourcetrailPythonIndexer is already installed."
		exit
	fi
fi

dir
if [ ! -e "build" ]; then
	mkdir "build"
fi

dir

cd build
dir




if [ ! -e "temp" ]; then
	mkdir "./temp"
fi

dir
cd ..

where cmd

echo -e $INFO "starting to download $PACKAGE_FILE_NAME"

if [ $PLATFORM == "linux" ]; then
	wget -O $TEMP_PATH/$PACKAGE_FILE_NAME $PACKAGE_URL
elif [ $PLATFORM == "osx" ]; then
	wget -O $TEMP_PATH/$PACKAGE_FILE_NAME $PACKAGE_URL
elif [ $PLATFORM == "windows" ]; then
	certutil.exe -urlcache -split -f $PACKAGE_URL $TEMP_PATH/$PACKAGE_FILE_NAME
fi

echo -e $INFO "finished downloading $PACKAGE_FILE_NAME"


if [ $PLATFORM == "linux" ]; then
	unzip -d $TEMP_PATH $TEMP_PATH/$PACKAGE_FILE_NAME
elif [ $PLATFORM == "osx" ]; then
	unzip -d $TEMP_PATH $TEMP_PATH/$PACKAGE_FILE_NAME
elif [ $PLATFORM == "windows" ]; then
	winrar x $TEMP_PATH/$PACKAGE_FILE_NAME $TEMP_PATH
fi


echo -e $INFO "clearing $TARGET_PATH"
rm -rf $TARGET_PATH
mkdir -p $TARGET_PATH
cp -r $TEMP_PATH/$PACKAGE_NAME/* $TARGET_PATH


echo -e $INFO "clearing temporary data at $TEMP_PATH"
rm -rf $TEMP_PATH
