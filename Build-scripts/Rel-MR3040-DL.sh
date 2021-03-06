#! /bin/bash

# Default is for your local git repo to live in ../../Git
# If not, you can override by setting/exporting it in your .bashrc
: ${GITREPO="../../Git"}

# Select the repo to use
REPO="digital-library"
BRANCH="main"

echo "Set up version strings"
DIRVER="VER-1.0"
VER="Digital-Library-01-MR3040-"$DIRVER

echo "************************************"
echo ""
echo "Build script for Digital library TP-Link MR3040 device"

echo "Git directory: "$GITREPO
echo "Repo: "$REPO
echo " "

if [ ! -d $GITREPO"/"$REPO ]; then
	echo "Repo does not exist. Exiting build process"
	echo " "
	exit
fi

BUILD_DIR=$(pwd)
cd $BUILD_DIR
pwd

##############################

# Check to see if setup has already run
if [ ! -f ./already_configured ]; then 
  # make sure it only executes once
  touch ./already_configured  
  echo "Make builds directory"
  mkdir -p ./Builds/
  mkdir -p ./Builds/ar71xx/
  mkdir -p ./Builds/ar71xx/builds
  echo "Initial set up completed. Continuing with build"
  echo ""
else
  echo "Build environment is configured. Continuing with build"
  echo ""
fi

#########################

echo "Start build process"

BINDIR="./bin/targets/ar71xx/tiny"
BUILDDIR="./Builds/ar71xx"

###########################
echo "Copy files from Git repo into build folder"
echo "Source repo details: "$REPO $REPOID

rm -rf ./diglib-build/

cp -rp $GITREPO/$REPO/diglib-build/ .

cp -fp $GITREPO/$REPO/Build-scripts/FactoryRestore.sh  .

###########################

BUILDPWD=`pwd`
cd  $GITREPO/$REPO
echo "Get repo ID string"
REPOID=`git describe --long --dirty --abbrev=10 --tags`
cd $BUILDPWD
echo "Source repo details: "$REPO $REPOID

###########################

# Set up new directory name with date and version
DATE=`date +%Y-%m-%d-%H:%M`
DIR=$DATE"-MR3040-Digital-Library-"$DIRVER

###########################
# Set up build directory
echo "Set up new build directory  $BUILDDIR/builds/build-"$DIR
mkdir $BUILDDIR/builds/build-$DIR

# Create md5sums files
echo $DIR > $BUILDDIR/builds/build-$DIR/md5sums-$VER.txt

##########################

# Build function

function build() {

echo "Set up .config for "$1 $2
rm -f ./.config

if [ $2 ]; then
	echo "Config file: config-"$1-$2
	cp ./diglib-build/$1/config-$1-$2  ./.config
else
	echo "Config file: config-"$1
	cp ./diglib-build/$1/config-$1  ./.config
fi

echo "Run defconfig"
make defconfig > /dev/null

# Set target string
TARGET=$1

echo "Check .config version"
echo "Target:  " $TARGET
echo ""

echo "Set up files for "$1 $2
echo "Remove files directory"
rm -r ./files

echo "Copy base files"
cp -rf ./diglib-build/files     .  

echo "Overlay device specific files"
cp -rf ./diglib-build/$1/files  .  
echo ""

echo "Build Factory Restore tar file"
./FactoryRestore.sh	 
echo ""

echo "Check files directory"
ls -al ./files  
echo ""

echo "Version: " $VER $TARGET $2
echo "Date stamp: " $DATE

echo "Version:    " $VER $TARGET $2        > ./files/etc/secn_version
echo "Build date: " $DATE                 >> ./files/etc/secn_version
echo "Git:        " $REPO $REPOID         >> ./files/etc/secn_version
echo " "                                  >> ./files/etc/secn_version
echo ""

echo "Banner version info:"
cat ./files/etc/secn_version
echo ""

echo "Clean up any left over files"
rm $BINDIR/openwrt-*
echo ""

echo "Run make for "$1 $2
make -j1
#make -j3
#make -j1 V=s 2>&1 | tee ~/build.txt
echo ""

echo  "Rename files to add version info"
echo ""
if [ $2 ]; then
	for n in `ls $BINDIR/openwrt*.bin`; do mv  $n   $BINDIR/openwrt-$VER-$1-$2-`echo $n|cut -d '-' -f 5-10`; done
else
	for n in `ls $BINDIR/openwrt*.bin`; do mv  $n   $BINDIR/openwrt-$VER-$1-`echo $n|cut -d '-' -f 5-10`; done
fi

echo "Update md5sums file"
md5sum $BINDIR/*-squash*sysupgrade.bin >> $BUILDDIR/builds/build-$DIR/md5sums-$VER.txt
md5sum $BINDIR/*-squash*factory.bin >> $BUILDDIR/builds/build-$DIR/md5sums-$VER.txt

echo  "Move files to build folder"
mv $BINDIR/openwrt*-squash*sysupgrade.bin $BUILDDIR/builds/build-$DIR
mv $BINDIR/openwrt*-squash*factory.bin $BUILDDIR/builds/build-$DIR
echo ""

echo "Clean up unused files"
##rm $BINDIR/openwrt-*
echo ""

echo ""
echo "End "$1 $2" build"
echo ""
echo '----------------------------'
}

############################


echo '----------------------------'
echo " "
echo "Start Device builds"
echo " "
echo '----------------------------'

build MR3040 

echo " "
echo " Build script MR3040 Digital Library complete"
echo " "
echo '----------------------------'

exit


