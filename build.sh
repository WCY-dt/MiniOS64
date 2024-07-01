#!/bin/bash

if [ -d "./dist" ]; then
    rm -rf ./dist/*
else
    mkdir -p ./dist
fi

(cd ./boot && sh ./build.sh)
boot_result=$?

make -C ./kernel clean

(make -C ./kernel)
make_result=$?

if [ "$boot_result" = "0" ] && [ "$make_result" = "0" ]
then
    cat ./boot/dist/boot.bin ./kernel/dist/kernel.bin > ./dist/MiniOS.img

    fsize=$(wc -c < ./dist/MiniOS.img)
    sectors=$(( ($fsize + 511) / 512 ))
    dd if=/dev/zero bs=1 count=$(( 512 * sectors - fsize )) >> ./dist/MiniOS.img

    echo "Build finished successfully"
    echo "ALERT: Adjust boot sector to load $sectors sectors"
else
    result=`expr $boot_result + $make_result`
    echo "Build failed with error code $result. See output for more info."
fi