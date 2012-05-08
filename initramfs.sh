#!/bin/bash

# This script will build for all listed devices by default

# To build for one device only, use ./initramfs.sh "phone name" (without quote)
# Example : ./initramfs.sh captivate

export USE_CCACHE=1

        CCACHE=ccache
        CCACHE_COMPRESS=1
        CCACHE_DIR=~/aokpsgs/kernel/samsung/.ramdisks-ccache
        export CCACHE_DIR CCACHE_COMPRESS

declare -A phone

if [[ $# -gt 0 ]]; then
	phones[0]=$1
	echo " "
	echo "================Force building for $1 only=================="

else
	phones[0]="galaxys"
	phones[1]="fascinate"
	phones[2]="captivate"
	phones[3]="vibrant"
fi

cd ../../../

for i in ${!phones[@]}; do
	phone=${phones[$i]}

echo "========Building ramdisk.img and recovery.img for ${phone}========"
echo ""
. build/envsetup.sh && breakfast aokp_${phone}mtd-userdebug && make bootimage -j12
done

echo "Done!"
