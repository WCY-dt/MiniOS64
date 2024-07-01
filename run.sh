#!/bin/bash

# 检查 qemu-system-x86_64 是否已安装
if ! command -v qemu-system-x86_64 >/dev/null 2>&1; then
    echo "qemu-system-x86_64 could not be found, please install it first."
    exit 1
fi

# 检查 dist/MiniOS.img 文件是否存在
if [ ! -f "dist/MiniOS.img" ]; then
    echo "Boot file dist/boot.bin not found, please run build.sh first."
    exit 1
fi

# 使用 qemu-system-x86_64 运行 dist/MiniOS.img
qemu-system-x86_64 -drive format=raw,file=dist/MiniOS.img

# 检查 qemu 是否成功启动
if [ $? -eq 0 ]; then
    echo "qemu-system-x86_64 successfully started the boot image."
else
    echo "Failed to start qemu-system-x86_64 with the boot image."
    exit 1
fi