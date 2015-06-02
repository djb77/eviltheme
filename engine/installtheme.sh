#!/sbin/sh

# Enhanced VRTheme engine v2.0.3
# Copyright Aurel Jared Dantis, 2014-2015.
#
# Original VRTheme engine is copyright
# VillainROM 2011. All rights reserved.
# Edify-like methods defined below are
# copyright Chainfire 2011.

# Declare busybox and output file descriptor
bb="/tmp/busybox"
datetime=$($bb date +"%m%d%y-%H%M%S")
OUTFD=$(ps | grep -v "grep" | grep -o -E "update_binary(.*)" | cut -d " " -f 3);

[ $OUTFD != "" ] || OUTFD=$(ps | grep -v "grep" | grep -o -E "updater(.*)" | cut -d " " -f 3);

# Check if ROM is Lollipop+ or not
lpfiletree=$(ls /system/priv-app | grep -i '.apk')
if [ ! "$lpfiletree" ]; then
	lollipop="1"
	ui_print "- Adjusting engine for new app hierarchy"
	checkdex() {
		tmpvar=$(echo $2 | $bb sed -e 's/\.apk//g')
		if [ -e ./classes.dex ]; then
			rm -f "/data/dalvik-cache/arm/system@$1@$tmpvar@$2.apk@classes.dex"
		fi
	}
else
	checkdex() {
		if [ -e ./classes.dex ]; then
			if [ -e "/data/dalvik-cache/system@$1@$2@classes.dex" ]; then
				rm -f "/data/dalvik-cache/system@$1@$2@classes.dex"
			else
				rm -f "/cache/dalvik-cache/system@$1@$2@classes.dex"
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
	if [ ! -d "$1" ]; then
		$bb mkdir -p "$1"
	fi
}
zpln() {
	if [ "$lollipop" -eq "1" ]; then
		appDir=$(echo $1 | sed "s/\/$1\.apk")
		$bb mkdir -p ./aligned/$appDir
	fi
	/tmp/zipalign -f -v 4 $1 ./aligned/$1
}
friendlyname() {
	tempvar="$(echo $1 | $bb sed 's/.apk//g')"
	echo "$tempvar"
}

# I don't think functions work well for this purpose
theme="/tmp/zip -r"

# Declare location shortcuts
vrroot="/data/tmp/eviltheme"
vrbackup="/data/tmp/evt-backup"

# Make directories
dir "$vrbackup"
dir "$vrroot/apply"

# Theme the apps
ui_print "- Themeing apps"
[ -d "$vrroot/system/app" ] && sysapps=1 || sysapps=0
[ -d "$vrroot/system/priv-app" ] && privapps=1 || privapps=0
[ -d "$vrroot/system/framework" ] && framework=1 || framework=0

if [ "$sysapps" -eq "1" ]; then
	cd "$vrroot/system/app/"
	dir aligned

	for f in *.apk; do
		cd "$f"

		# Backup APK
		if [ "$lollipop" -eq "1" ]; then
			appPath="$(friendlyname $f)/$f"
			dir "$vrbackup/system/app/$(friendlyname $f)"
			dir "$vrroot/apply/system/app/$(friendlyname $f)"
			cp "/system/app/$appPath" "$vrbackup/system/app/$(friendlyname $f)/"
			cp "/system/app/$appPath" "$vrroot/apply/system/app/$(friendlyname $f)/"
		else
			dir "$vrbackup/system/app/"
			dir "$vrroot/apply/system/app/"
			cp "/system/app/$f" "$vrbackup/system/app/"
			cp "/system/app/$f" "$vrroot/apply/system/app/"
			appPath="$f"
		fi

		ui_print "  * $appPath"

		# Theme APK
		mv "$vrroot/apply/system/app/$appPath" "$vrroot/apply/system/app/$appPath.zip"
		$theme "$vrroot/apply/system/app/$appPath.zip" ./*
		mv "$vrroot/apply/system/app/$appPath.zip" "$vrroot/apply/system/app/$appPath"

		# Refresh bytecode if necessary
		checkdex "app" "$f"
		cd ../

		# Zipalign APK
		zpln "$appPath"

		# Replace old APK
		$bb cp -f "aligned/$appPath" "/system/app/$appPath"

	done
fi
if [ "$privapps" -eq "1" ]; then
	cd "$vrroot/system/priv-app/"
	dir aligned

	for f in *.apk; do
		cd "$f"

		# Backup APK
		if [ "$lollipop" -eq "1" ]; then
			appPath="$(friendlyname $f)/$f"
			dir "$vrbackup/system/priv-app/$(friendlyname $f)"
			dir "$vrroot/apply/system/priv-app/$(friendlyname $f)"
			cp "/system/priv-app/$appPath" "$vrbackup/system/priv-app/$(friendlyname $f)/"
			cp "/system/priv-app/$appPath" "$vrroot/apply/system/priv-app/$(friendlyname $f)/"
		else
			dir "$vrbackup/system/priv-app/"
			dir "$vrroot/apply/system/priv-app/"
			cp "/system/priv-app/$f" "$vrbackup/system/priv-app/"
			cp "/system/priv-app/$f" "$vrroot/apply/system/priv-app/"
			appPath="$f"
		fi

		ui_print "  * $appPath"

		# Theme APK
		mv "$vrroot/apply/system/priv-app/$appPath" "$vrroot/apply/system/priv-app/$appPath.zip"
		$theme "$vrroot/apply/system/priv-app/$appPath.zip" ./*
		mv "$vrroot/apply/system/priv-app/$appPath.zip" "$vrroot/apply/system/priv-app/$appPath"

		# Refresh bytecode if necessary
		checkdex "priv-app" "$f"
		cd ../

		# Zipalign APK
		zpln "$appPath"

		# Replace old APK
		$bb cp -f "aligned/$appPath" "/system/priv-app/$appPath"
	done
fi

if [ "$framework" -eq "1" ]; then
	cd "$vrroot/system/framework/"
	dir aligned
	dir "$vrbackup/system/framework/"
	dir "$vrroot/apply/system/framework/"

	for f in *.apk; do
		cd "$f"

		# Backup APK
		cp "/system/framework/$f" "$vrbackup/system/framework/"
		cp "/system/framework/$f" "$vrroot/apply/system/framework/"

		ui_print "  * $f"

		# Theme APK
		mv "$vrroot/apply/system/framework/$f" "$vrroot/apply/system/framework/$f.zip"
		$theme "$vrroot/apply/system/framework/$f.zip" ./*
		mv "$vrroot/apply/system/framework/$f.zip" "$vrroot/apply/system/framework/$f"

		# Refresh bytecode if necessary
		checkdex "framework" "$f"
		cd ../

		# Zipalign APK
		zpln "$f"

		# Replace old APK
		$bb cp -f "aligned/$f" /system/framework/
	done
fi

# Create flashable restore zip
ui_print "- Creating restore zip in /data/eviltheme-backup"
cd "$vrbackup"
dir /data/eviltheme-backup
mv /data/tmp/eviltheme/vrtheme_restore.zip "/data/tmp/eviltheme/restore-$datetime.zip"
$theme "/data/tmp/eviltheme/restore-$datetime.zip" ./*
mv "/data/tmp/eviltheme/restore-$datetime.zip" "/data/eviltheme-backup/restore-$datetime.zip"

# Cleanup
ui_print "- Cleaning up"
$bb rm -fR /data/tmp/eviltheme
ui_print "Done. If your device does not perform properly after this,"
ui_print "just flash /data/eviltheme-backup/restore-$datetime.zip."

exit 0
