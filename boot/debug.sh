#!/bin/bash
# 使用 qemu-system-x86_64 运行 dist/boot.bin
qemu-system-x86_64 -drive format=raw,file=dist/boot.bin