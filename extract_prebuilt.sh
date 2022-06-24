#!/bin/bash

# Copyright (C) 2022 Jvlong2019 <together08@yeah.net>
# Scripts for extracting prebuilt kernel and header modules from stock for Meizu 18 series.

# Only support Windows Mingw (Git Bash) and Linux amd64.

LOCALDIR=$(cd "$( dirname ${BASH_SOURCE[0]} )" && pwd)
cd $LOCALDIR

read -p "Put update.zip here and press enter..."

# Detect OS and decide what binaries to use
os=$(uname -o)
if [ "$os" = "Msys" ]; then
    oss="Windows"
    payload_dumper="bin/$oss/payload-dumper-go.exe"
    sevenzip="bin/$oss/7za.exe"
    imgextract="bin/$oss/imgextractor.exe"
    aik_unpack="cmd.exe /C bin\\$oss\\AIK\\unpackimg"
    aik_cleanup="cmd.exe /C bin\\$oss\\AIK\\cleanup"
elif [ "$os" = "GNU/Linux" ]; then
    oss="Linux"
    payload_dumper="bin/$oss/payload-dumper-go"
    sevenzip="7za"
    imgextract="python3 bin/$oss/imgextractor.py"
    aik_unpack="bin/$oss/AIK/unpackimg.sh"
    aik_cleanup="bin/$oss/AIK/cleanup.sh"
else
    echo "OS not supported!"
    exit 1
fi
echo "You are now using $oss"

# Out dir
read -p "Enter the device's codename you're extracting for: " codename
day=$(date "+%Y%m%d")
outdir="$codename"_prebuilt_"$day"

if [ -d "$outdir" ]; then
    rm -rf "$outdir"
fi

mkdir "$outdir"
mkdir "$outdir"/final
mkdir "$outdir"/final/modules
mkdir "$outdir"/final/modules/vendor
mkdir "$outdir"/final/modules/vendor_boot

# Extract update.zip
if [ ! -e "$LOCALDIR/update.zip" ]; then
    echo "update.zip not found!!!"
    exit 1
fi
echo "Unzipping update.zip..."

$sevenzip e "$LOCALDIR"/update.zip payload.bin

# Extract payload.bin
echo "Extracting payload.bin..."
if [ -e "$LOCALDIR/payload.bin" ]; then
    rm "$LOCALDIR/payload.bin"
fi
$payload_dumper -p vendor,vendor_boot,boot -o $outdir payload.bin

# Extract vendor.img for vendor modules
echo "Extracting vendor.img..."
$imgextract "$outdir"/vendor.img $outdir/vendor_unpack
cp -fprn $outdir/vendor_unpack/vendor/lib/modules/* "$outdir"/final/modules/vendor

# Extract boot.img for kernel
echo "Extracting boot.img..."
cp $outdir/boot.img "bin/$oss/AIK"

$aik_unpack

cp "bin/$oss/AIK/split_img/boot.img-kernel" "$outdir"/final
mv "$outdir"/final/boot.img-kernel "$outdir"/final/kernel

$aik_cleanup
rm "bin/$oss/AIK/boot.img"

# Extract vendor_boot.img for dtb and vendor boot modules
echo "Extracting vendor_boot.img..."
cp $outdir/vendor_boot.img "bin/$oss/AIK"
mv "bin/$oss/AIK"/vendor_boot.img "bin/$oss/AIK"/boot.img

$aik_unpack

cp "bin/$oss/AIK/split_img/boot.img-dtb" "$outdir"/final
mv "$outdir"/final/boot.img-dtb "$outdir"/final/dtb

cp -fprn "bin/$oss/AIK/ramdisk/lib/modules/*" "$outdir"/final/modules/vendor_boot

$aik_cleanup
rm "bin/$oss/AIK/boot.img"

echo "Ready to go. See $outdir/final"