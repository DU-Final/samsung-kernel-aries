#!/system/xbin/sh
# 30datafix
#
# Move apps data to the ext4 /data partition then move back and create symbolic links
# ALL apps data subdirs (on yaffs /datadata partiton) BUT :
# "lib" and "libs" subdirectories AND
# selected apps "cache" subdirectories (apps name have to be put in /mnt/sdcard/move_cache.txt).
#
# This script may be run multiple times and should be run after one or more
# new apps are installed. This script is designed to be used as init.d script while it
# should be run regularly and doesn't spent many time when there's nothing to move.
#
# Background
# On Samsung Galaxy S, cyanogenmod 7 creates a ~175MB yaffs partition which
# holds all app data.  This partition is mounted at /datadata and the usual
# location of this directory at /data/data is a symbolic link that points
# to /datadata.
#
#       $ ls -l /data/data
#       lrwxrwxrwx      1 system        system  9 Oct  8 19:34 /data/data -> /datadata
#
# The app apk itself does not reside here, but data created by the app resides
# here, especially, the app's sqlite databases and user preference xml files.
# The cyanogenmod developers did it this way to address the lag experienced on
# the stock Galaxy S firmware.  But, this produces a problem.
#
# The /datadata partition is quite small and may be filled up quickly by an
# app that caches a lot of data (g+ for example).  Once /datadata fills up,
# apps will begin force closing since they will not be able to create any new
# data on /datadata.  The ext4 /data partition, which is about 2GB, has plenty
# of space free.  So, it is attractive to move /datadata onto this large
# partition.  But then we have the lag problem again.  That's where this script
# comes in.  It moves certain subdirectories from each app on the ext4 partition.
# Default select the "lib" & "libs" subdirectories as here are static files : with 
# only read access, ext4 performances are not so bad compared to yaffs ones.


####### Variables definition #######

datadata='/data/data'
yaffs='/datadata'

datafix_files_dir='/data/local/datafix'

# cache of apps listed in the file below will move/stay on /data/data
apps_cache_file='move_cache.txt'

# apps listed in the file below FULLY stay on /data/data
skip_apps_file='skip_apps.txt'

####### Script checks #######

# create datafix_files_dir if it doesn't exist
if [ ! -d "$datafix_files_dir" ]; then
	busybox mkdir -p "$datafix_files_dir"
fi

# let in /data/data cache subdirectories of apps in /mnt/sdcarddatafix/move_cache.txt
# create it if it doesn't exist
if [ ! -r "$datafix_files_dir/$apps_cache_file" ]; then
	busybox touch "$datafix_files_dir/$apps_cache_file"
fi

# let in /data/data apps in /mnt/sdcarddatafix/skip_apps.txt
# create it if it doesn't exist
if [ ! -r "$datafix_files_dir/$skip_apps_file" ]; then
	busybox touch "$datafix_files_dir/$skip_apps_file"
fi


####### Script Initialisation #######

# Move everything on /data/data (only once the first use of this script)
if [ -L "$datadata" ]; then
	busybox rm -r "$datadata.new"
	busybox cp -a "$yaffs" "$datadata.new" &&
	busybox rm -r "$datadata.new/lost+found" &&
	busybox rm "$datadata" &&
	busybox mv "$datadata.new" "$datadata" &&
	busybox rm -r "$yaffs/"*
	busybox touch "$datadata/.datafix_ng"
elif [ ! -e "$datadata/.datafix_ng" -a ! -L "$datadata" ]; then
	busybox rm -r "$datadata.new"
	busybox cp -aL "$datadata" "$datadata.new" &&
	busybox rm -r "$datadata.new/lost+found";
	busybox rm -r "$datadata" &&
	busybox mv "$datadata.new" "$datadata" &&
	busybox rm -r "$yaffs/"*
	busybox touch "$datadata/.datafix_ng"
fi

####### Datafix part #######

cd "$datadata" &&
for app in *; do
	busybox grep "$app" "$datafix_files_dir/$skip_apps_file" && continue
	cd "$app" &&
	for d in *; do
		fowner="`busybox ls -ld $d | busybox awk '{print $3}'`";
		fgroup="`busybox ls -ld $d | busybox awk '{print $4}'`";
		# if subdir is not "lib" and not "libs" and is a directory
		if [[  "$d" != "lib" && "$d" != "libs"  && -d "$d" ]]; then
			temp_test_cache=$(busybox grep "$app" "$datafix_files_dir/$apps_cache_file");
			# if it's a cache subdirectory *and* users want current app cache subdir stay/move on /data/data
			if [ "$d" = "cache" -a  -n "$temp_test_cache" ]; then
				# if it's a symlink (previously moved to /datadata)
				if [ -L "$d" ]; then
					echo "Moving $app/$d back to $datadata ..." &&
					busybox rm -Rf "$datadata/$app/$d" &&
					busybox cp -a "$yaffs/$app/$d" "$datadata/$app" &&
					busybox rm -Rf "$yaffs/$app/$d"
				fi
			# else it's not lib nor libs nor "/data/data" cache and it's a directory
			else
				# if is not (already) a symlink
				if [ ! -L "$d" ]; then
					echo "Processing $app/$d..." &&
					if [ -d "$yaffs/$app/$d" ]; then
						busybox rm -Rf "$yaffs/$app/$d"
					fi &&
					busybox mkdir -p "$yaffs/$app/$d" &&
					busybox cp -a "$datadata/$app/$d" "$yaffs/$app" &&
					busybox rm -Rf "$datadata/$app/$d" &&
					busybox ln -s "$yaffs/$app/$d" "$d" &&
					busybox chown $fowner.$fgroup "$yaffs/$app" "$yaffs/$app/$d"
					busybox chown -h $fowner.$fgroup "$d" ||
					echo 1>&2 "Error: failed moving $app/$d"
				fi
			fi
		fi
	done
	cd "$datadata"
done


####### Datafix cleaning #######

# Cleaning removed apps static parts (if needed)
cd "$yaffs" &&
for d in *; do
	if [ $d = "lost+found" ] ; then continue; fi
	if [ -d "$d" -a ! -d "$datadata/$d" ]; then
		echo "Removing stale app resources $d..."
		busybox rm -r "$d"
	fi
done
