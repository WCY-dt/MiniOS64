#!/bin/bash

# 检查 nasm 是否已安装
if ! command -v nasm >/dev/null 2>&1; then
    echo "nasm could not be found, please install it first."
    exit 1
fi

# 检查源文件是否存在
if [ ! -f "boot.asm" ]; then
    echo "Source file boot.asm not found."
    exit 1
fi

# 创建输出目录（如果不存在）
mkdir -p dist

# 编译源文件
nasm -f bin boot.asm -o dist/boot.bin

# 检查编译是否成功
if [ $? -eq 0 ]; then
    echo "Compilation successful. Output file is located at dist/boot.bin"
else
    echo "Compilation failed."
    exit 1
fi