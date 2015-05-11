#!/sbin/sh

# Enhanced VRTheme engine v2.0
# Copyright Aurel Jared Dantis, 2014-2015.
#
# Original VRTheme engine is copyright
# VillainROM 2011. All rights reserved.
# Edify-like methods defined below are
# copyright Chainfire 2011.

# Declare busybox and output file descriptor
bb="/tmp/busybox"
OUTFD=$(ps | grep -v "grep" | grep -o -E "update_binary(.*)" | cut -d " " -f 3);

[ $OUTFD != "" ] || OUTFD=$(ps | grep -v "grep" | grep -o -E "updater(.*)" | cut -d " " -f 3);

# Check if ROM is Lollipop+ or not
lpfiletree=$(ls /system/priv-app | grep -i '.apk')
if [ $lpfiletree == "" ]; then
	lollipop="1"
	ui_print "- Adjusting engine for new app hierarchy"
	checkdex() {
		tmpvar=$(echo $2 | $bb sed -e 's/\.apk//g')
		if [ -e ./classes.dex ]; then
			rm -f /data/dalvik-cache/arm/system@$1@$tmpvar@$2.apk@classes.dex
		fi
	}
else
	checkdex() {
		if [ -e ./classes.dex ]; then
			if [ -e "/data/dalvik-cache/system@$1@$tmpvar@$2.apk@classes.dex" ]; then
				rm -f /data/dalvik-cache/system@$1@$tmpvar@$2.apk@classes.dex
			else
				rm -f /cache/dalvik-cache/system@$1@$tmpvar@$2.apk@classes.
			fi
		fi
	}
fi

# Define some methods
ui_print() {
	if [ $OUTFD != "" ]; then
		echo "ui_print ${1} " 1>&$OUTFD;
		echo "ui_print " 1>&$OUTFD;
	else
		echo "${1}";
	fi;
}
dir() {
	$bb mkdir -p $1
}
zpln() {
	if [ "$lollipop" -eq "1" ]; then
		appDir=$(echo $1 | sed "s/\/$1\.apk")
		$bb mkdir -p ./aligned/$appDir
	fi
	/tmp/zipalign -f -v 4 $1 ./aligned/$1
}
theme() {
	/tmp/zip -r -q $1 $2
}

# Declare location shortcuts
vrroot="/data/tmp/eviltheme"
vrbackup="/data/tmp/evt-backup"
sysdir="/system/app"
privdir="/system/priv-app"
fwdir="/system/framework"

# Make directories
dir $vrbackup
dir $vrroot/apply
for d in $(ls $vrroot/apply/system/); do
	mkdir -p "$vrbackup/$d"
done

# Theme the apps
ui_print "- Themeing apps"

if [ "$sysapps" -eq "1" ]; then
	cd $vrroot/system/app/
	dir aligned

	for f in $(ls); do
		# Backup APK
		if [ "$lollipop" -eq "1" ]; then
			dir $vrbackup/system/app/$f
			dir $vrroot/apply/system/app/$f
			cp /system/app/$f/$f.apk $vrbackup/system/app/$f/
			cp /system/app/$f/$f.apk $vrroot/apply/system/app/$f/
			appPath="$f/$f.apk"
		else
			cp /system/app/$f $vrbackup/system/app/
			cp /system/app/$f $vrroot/apply/system/app/
			appPath="$f"
		fi

		ui_print "* $appPath"

		# Theme APK
		mv $vrroot/apply/system/app/$appPath $vrroot/apply/system/app/$appPath.zip
		theme $vrroot/apply/system/app/$appPath.zip *
		mv $vrroot/apply/system/app/$appPath.zip $vrroot/apply/system/app/$appPath

		# Refresh bytecode if necessary
		checkdex "app" "$f"

		# Zipalign APK
		zpln $appPath

		# Replace old APK
		cp aligned/$appPath /system/app/
	done
fi
if [ "$privapps" -eq "1" ]; then
	cd $vrroot/system/priv-app/
	dir aligned

	for f in $(ls); do
		# Backup APK
		if [ "$lollipop" -eq "1" ]; then
			dir $vrbackup/system/priv-app/$f
			dir $vrroot/apply/system/priv-app/$f
			cp /system/priv-app/$f/$f.apk $vrbackup/system/priv-app/$f/
			cp /system/priv-app/$f/$f.apk $vrroot/apply/system/priv-app/$f/
			appPath="$f/$f.apk"
		else
			cp /system/priv-app/$f $vrbackup/system/priv-app/
			cp /system/priv-app/$f $vrroot/apply/system/priv-app/
			appPath="$f"
		fi

		ui_print "* $appPath"

		# Theme APK
		mv $vrroot/apply/system/priv-app/$appPath $vrroot/apply/system/priv-app/$appPath.zip
		theme $vrroot/apply/system/priv-app/$appPath.zip *
		mv $vrroot/apply/system/priv-app/$appPath.zip $vrroot/apply/system/priv-app/$appPath

		# Refresh bytecode if necessary
		checkdex "priv-app" "$f"

		# Zipalign APK
		zpln $appPath

		# Replace old APK
		cp aligned/$appPath /system/priv-app/
	done
fi

if [ "$framework" -eq "1" ]; then
	cd $vrroot/system/framework/
	dir aligned

	for f in $(ls); do
		# Backup APK
		if [ "$lollipop" -eq "1" ]; then
			dir $vrbackup/system/framework/$f
			dir $vrroot/apply/system/framework/$f
			cp /system/framework/$f/$f.apk $vrbackup/system/framework/$f/
			cp /system/framework/$f/$f.apk $vrroot/apply/system/framework/$f/
			appPath="$f/$f.apk"
		else
			cp /system/framework/$f $vrbackup/system/framework/
			cp /system/framework/$f $vrroot/apply/system/framework/
			appPath="$f"
		fi

		ui_print "* $appPath"

		# Theme APK
		mv $vrroot/apply/system/framework/$appPath $vrroot/apply/system/framework/$appPath.zip
		theme $vrroot/apply/system/framework/$appPath.zip *
		mv $vrroot/apply/system/framework/$appPath.zip $vrroot/apply/system/framework/$appPath

		# Refresh bytecode if necessary
		checkdex "framework" "$f"

		# Zipalign APK
		zpln $appPath

		# Replace old APK
		cp aligned/$appPath /system/framework/
	done
fi

# Create flashable restore zip
datetime=$($bb date +"%m%d%y-%H%M%S")
cd $vrbackup
dir /data/eviltheme-backup
mv /data/tmp/eviltheme/vrtheme_restore.zip /data/tmp/eviltheme/restore-$datetime.zip
theme /data/tmp/eviltheme/restore-$datetime.zip *
mv /data/tmp/eviltheme/restore-$datetime.zip /data/eviltheme-backup

# Cleanup

exit 0
