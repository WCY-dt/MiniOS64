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
  kernel_size_bytes=$(wc -c < ./kernel/dist/kernel.bin)
  kernel_size_sectors=$(( ($kernel_size_bytes + 511) / 512 ))
  printf %02x $kernel_size_sectors | xxd -r -p | dd of=./boot/dist/boot.bin bs=1 seek=2 count=1 conv=notrunc
  echo "Kernel size in sectors: $kernel_size_sectors"

  cat ./boot/dist/boot.bin ./kernel/dist/kernel.bin > ./dist/MiniOS.img

  echo "Build finished successfully"
else
  result=`expr $boot_result + $make_result`
  echo "Build failed with error code $result. See output for more info."
fi