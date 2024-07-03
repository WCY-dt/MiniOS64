# Compiler and assembler tools
CC = gcc
LD = ld
ASM = nasm
QEMU = qemu-system-x86_64
GDB = gdb

# Compilation flags
CFLAGS = -ffreestanding -ggdb -Ikernel/include -Idrivers/include
LDFLAGS = -T kernel.ld
LDFLAGS_BIN = ${LDFLAGS} --oformat binary
ASMFLAGS = -f elf64

# Kernel & Drivers files
C_SOURCES = $(wildcard kernel/src/*.c drivers/src/*.c)
HEADERS = $(wildcard kernel/include/*.h drivers/include/*.h)
OBJ = $(patsubst %.c,dist/kernel/%.o,$(notdir $(C_SOURCES)))

.PHONY: all clean run debug

all: clean directories dist/boot/boot.bin dist/kernel/kernel.bin dist/kernel/kernel.elf dist/MiniOS.img

# Create output directories if they don't exist
directories:
	@mkdir -p dist/boot
	@mkdir -p dist/kernel

# Build bootloader
dist/boot/boot.bin: boot/boot.asm
	cd boot && ${ASM} -f bin -o ../$@ boot.asm

# Build kernel
dist/kernel/kernel.bin: dist/kernel/entry.o ${OBJ}
	${LD} ${LDFLAGS_BIN} -o $@ $^

dist/kernel/kernel.elf: dist/kernel/entry.o ${OBJ}
	${LD} ${LDFLAGS} -o $@ $^

dist/kernel/%.o: kernel/src/%.c ${HEADERS}
	${CC} ${CFLAGS} -o $@ -c $<

dist/kernel/%.o: drivers/src/%.c ${HEADERS}
	${CC} ${CFLAGS} -o $@ -c $<

dist/kernel/entry.o: kernel/entry.asm
	${ASM} ${ASMFLAGS} -o $@ $^

# Create final OS image
dist/MiniOS.img: dist/boot/boot.bin dist/kernel/kernel.bin
	kernel_size_bytes=$(shell wc -c < dist/kernel/kernel.bin); \
	kernel_size_sectors=$$(( ($$kernel_size_bytes + 511) / 512 )); \
	printf %02x $$kernel_size_sectors | xxd -r -p | dd of=dist/boot/boot.bin bs=1 seek=2 count=1 conv=notrunc;
	cat $^ > $@;

# Clean build artifacts
clean:
	@rm -rf dist

# Run QEMU
run: dist/MiniOS.img
	@${QEMU} -drive format=raw,file=$^

# Run QEMU with GDB
debug: dist/MiniOS.img dist/kernel/kernel.elf
	@${QEMU} -drive format=raw,file=dist/MiniOS.img -s -S & ${GDB} -ex "target remote localhost:1234" -ex "symbol-file dist/kernel/kernel.elf"
