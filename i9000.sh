#!/bin/sh

export USE_CCACHE=1

        CCACHE=ccache
        CCACHE_COMPRESS=1
        CCACHE_DIR=/home/dominik/android/ccache
        export CCACHE_DIR CCACHE_COMPRESS
###########################################################################################################
number="$1"
rom=""

handy="i9000"

build="Devil3"_"$number""$rom"_"$handy"

##########################################################################################################
target="$2"

scheduler="$3"

##########################################################################################################

mem=""

##########################################################################################################

color="CMC"

light="BLN"

version="$build"_"$scheduler"_"$light"_"$color"

# export KBUILD_BUILD_VERSION="$build"_"$scheduler"_"$color"
sed "/Devil/c\ \" ("$version")\"" init/version.c > init/version.neu
mv init/version.c init/version.backup
mv init/version.neu init/version.c
echo "building kernel"

	if [ "$rom" = "sense"  ] 
	then
	make sense_i9000_defconfig
	else
	make aries_galaxysmtd_defconfig
	fi

if [ "$scheduler" = "BFS"  ]
then
	sed -i 's/^.*SCHED_BFS.*$//' .config
	echo 'CONFIG_SCHED_BFS=y' >> .config
else
	sed -i 's/^.*SCHED_BFS.*$//' .config
echo 'CONFIG_SCHED_BFS=n
CONFIG_CGROUP_CPUACCT=y
CONFIG_CGROUP_SCHED=y
CONFIG_FAIR_GROUP_SCHED=y
CONFIG_RT_GROUP_SCHED=y
CONFIG_SCHED_AUTOGROUP=y
# CONFIG_CFS_BANDWIDTH is not set
# CONFIG_RCU_TORTURE_TEST is not set' >> .config
fi

################################### Config ###############################################################
sed -i 's/^.*FB_VOODOO.*$//' .config
echo 'CONFIG_FB_VOODOO=n
CONFIG_FB_VOODOO_DEBUG_LOG=n' >> .config
##########################################################################################################

find . -name "*.ko" -exec rm -rf {} \; 2>/dev/null || exit 1
make -j4 modules
find . -name "*.ko" -exec cp {} usr/galaxysmtd_initramfs/files/modules/ \; 2>/dev/null || exit 1

make -j4 zImage

echo "creating boot.img"
cp arch/arm/boot/zImage ./release/zImage
cp arch/arm/boot/zImage ./release/boot.img

echo "launching packaging script"

. ./packaging.inc
release "${version}"

#################################################################################################################


#######################################################################################################
#				VOODOO COLOR
#######################################################################################################
##########################################################################################################

mem=""

##########################################################################################################

color="VC"

light="BLN"
version="$build"_"$scheduler"_"$light"_"$color"

# export KBUILD_BUILD_VERSION="$build"_"$scheduler"_"$color"
sed "/Devil/c\ \" ("$version")\"" init/version.c > init/version.neu
mv init/version.c init/version.backup
mv init/version.neu init/version.c
echo "building kernel"

	if [ "$rom" = "sense"  ] 
	then
	make sense_i9000_defconfig
	else
	make aries_galaxysmtd_defconfig
	fi

if [ "$scheduler" = "BFS"  ]
then
	sed -i 's/^.*SCHED_BFS.*$//' .config
	echo 'CONFIG_SCHED_BFS=y' >> .config
else
	sed -i 's/^.*SCHED_BFS.*$//' .config
echo 'CONFIG_SCHED_BFS=n
CONFIG_CGROUP_CPUACCT=y
CONFIG_CGROUP_SCHED=y
CONFIG_FAIR_GROUP_SCHED=y
CONFIG_RT_GROUP_SCHED=y
CONFIG_SCHED_AUTOGROUP=y
# CONFIG_CFS_BANDWIDTH is not set
# CONFIG_RCU_TORTURE_TEST is not set' >> .config
fi

################################### Config ###############################################################
sed -i 's/^.*FB_VOODOO.*$//' .config
echo 'CONFIG_FB_VOODOO=y
CONFIG_FB_VOODOO_DEBUG_LOG=n' >> .config
##########################################################################################################
find . -name "*.ko" -exec rm -rf {} \; 2>/dev/null || exit 1

make -j4 modules

find . -name "*.ko" -exec cp {} usr/galaxysmtd_initramfs/files/modules/ \; 2>/dev/null || exit 1

make -j4 zImage

echo "creating boot.img"
cp arch/arm/boot/zImage ./release/zImage
cp arch/arm/boot/zImage ./release/boot.img

echo "launching packaging script"

. ./packaging.inc
release "${version}"

#############################################################################################################
echo "all done!"

rm arch/arm/boot/compressed/piggy.xzkern
