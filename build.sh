#!/bin/bash

#bash ./clean.sh

# check THEOS settings
if [ -z "$THEOS" ]; then
    echo "THEOS environment variable not set"
    exit 1
fi

if [ ! -d "$THEOS/lib" ]; then
    echo "THEOS lib [$THEOS/lib] not exists"
    exit 1
fi

# set temp working dir
#rm -rf .theos_building
mkdir -p .theos_building

######################################################
# build static lib for iOS using golib
######################################################
set -e
PWD=`pwd`

# build arm64
export CGO_ENABLED=1
export GOARCH=arm64
export GOOS=darwin
export CC=$PWD/clangwrap.sh
export CXX=$PWD/clangwrap.sh


echo "building darwin/arm64 static lib"
go build -buildmode=c-archive -o ./.theos_building/libgolang_arm64.a
if [ ! -f ./.theos_building/libgolang_arm64.a ]; then
    echo "failed to build darwin/arm64 static lib!"
    exit 1
fi

# # build armv7
export CGO_ENABLED=1
export GOARCH=arm
export GOARM=7
export CC=$PWD/clangwrap.sh
export CXX=$PWD/clangwrap.sh

# echo "building darwin/armv7 static lib"
go build -buildmode=c-archive -o ./.theos_building/libgolang_armv7.a
if [ ! -f ./.theos_building/libgolang_armv7.a ]; then
    echo "failed to build darwin/armv7 static lib!"
    exit 1
fi

# # Make universal library
cd ./.theos_building/
echo "joining darwin/arm64 & darwin/armv7 static libs to a universal one"
lipo libgolang_arm64.a libgolang_armv7.a -create -output libgolanguniversal.a
#cp libgolang_arm64.a  libgolanguniversal.a
rm libgolang_arm64.a libgolang_armv7.a
rm libgolang_arm64.h libgolang_armv7.h

# cd ./.theos_building/
# cp libgolang_arm64.a  libgolanguniversal.a
# if [ ! -f libgolanguniversal.a ]; then
#     echo "failed to build the universal lib!"
#     exit 1
# fi

######################################################
# build debian binary for iOS using theos
######################################################

# move static lib to theos lib folder
currentTime=$(date +%s)
staticLibFileName="libgolang"$currentTime".a"
staticLibLdFlags="-lgolang"$currentTime
cp libgolanguniversal.a $THEOS"/lib/"$staticLibFileName

# currentTime=$(date +%s)
# staticLibFileName="libfzfgolang.a"
# staticLibLdFlags="-lfzfgolang"
# cp libgolanguniversal.a $THEOS"/lib/"$staticLibFileName

# Makefile of .deb package
echo 'include $(THEOS)/makefiles/common.mk

export ARCHS = armv7 arm64

TOOL_NAME = fzf
fzf_FILES = main.mm
fzf_LDFLAGS = '$staticLibLdFlags'

include $(THEOS_MAKE_PATH)/tool.mk
' > ./Makefile

# control file of .deb package
echo 'Package: com.bbarrows.fzf
Name: fzf
Depends: 
Version: 0.0.1
Architecture: iphoneos-arm
Description: fzf fuzzy string search cli tool 
Maintainer: bbarrows
Author: bbarrows
Section: System
Tag: role::development
' > ./control

# copy main.h and main.mm to dest
cp ../main.mm ../main.h ./

# make the deb package
echo "building theos package"
make package

# ######################################################
# # extract the single program from deb package
# ######################################################
echo "extracting executable file from .deb package"
mkdir extracted_deb
echo "Debs in `pwd` packages"
dpkg -x packages/*.deb ./extracted_deb
cp packages/*.deb ../
mkdir -p ../bin
find ./extracted_deb -name "golangtool"|while read line; do cp $line ../bin/fzf-ios; done

# #remove temp path
cd ..
# #rm -rf ./.theos_building/
rm $THEOS"/lib/libgolang"*".a"
