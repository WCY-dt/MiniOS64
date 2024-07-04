# Compiler and assembler tools
CC = gcc
LD = ld
ASM = nasm
QEMU = qemu-system-x86_64
GDB = gdb

# Compilation flags
CFLAGS = -ffreestanding -ggdb -Iinclude
LDFLAGS = -T kernel.ld
LDFLAGS_BIN = ${LDFLAGS} --oformat binary
ASMFLAGS = -f elf64

# Kernel & Drivers files
C_SOURCES = $(wildcard init/*.c)
HEADERS = $(wildcard include/*.h)
OBJ = $(patsubst %.c,dist/init/%.o,$(notdir $(C_SOURCES)))

.PHONY: all clean run debug

all: clean directories dist/boot/boot.bin dist/kernel.bin dist/kernel.elf dist/MiniOS.img

# Create output directories if they don't exist
directories:
	@mkdir -p dist/boot
	@mkdir -p dist/init

# Build bootloader
dist/boot/boot.bin: boot/boot.asm
	cd boot && ${ASM} -f bin -o ../$@ boot.asm

# Build kernel
dist/kernel.bin: dist/boot/entry.o ${OBJ}
	${LD} ${LDFLAGS_BIN} -o $@ $^

dist/kernel.elf: dist/boot/entry.o ${OBJ}
	${LD} ${LDFLAGS} -o $@ $^

dist/init/%.o: init/%.c ${HEADERS}
	${CC} ${CFLAGS} -o $@ -c $<

dist/boot/entry.o: boot/entry.asm
	${ASM} ${ASMFLAGS} -o $@ $^

# Create final OS image
dist/MiniOS.img: dist/boot/boot.bin dist/kernel.bin
	kernel_size_bytes=$(shell wc -c < dist/kernel.bin); \
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
debug: dist/MiniOS.img dist/kernel.elf
	@${QEMU} -drive format=raw,file=dist/MiniOS.img -s -S & ${GDB} -ex "target remote localhost:1234" -ex "symbol-file dist/kernel.elf"
