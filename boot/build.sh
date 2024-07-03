# 创建输出目录（如果不存在）
mkdir -p dist

# 编译源文件
nasm -f bin boot.asm -o dist/boot.bin