CC = gcc
LD = ld
AS = nasm
QEMU = qemu-system-x86_64
GDB = gdb

CFLAGS = -ffreestanding -ggdb -Iinclude
LDFLAGS = -Ttext 0x8200
LDFLAGS_BIN = ${LDFLAGS} --oformat binary
ASFLAGS = -f elf64

C_SOURCES = $(wildcard init/*.c kernel/*.c drivers/*.c)
HEADERS = $(wildcard include/*.h)
OBJ = $(patsubst %.c, dist/kernel/%.o, ${C_SOURCES})

.PHONY: all clean run debug

all: clean directories dist/boot/boot.bin dist/kernel/kernel.bin dist/kernel.elf dist/MiniOS.img

directories:
	@mkdir -p dist/boot
	@mkdir -p dist/kernel/init
	@mkdir -p dist/kernel/kernel
	@mkdir -p dist/kernel/drivers

dist/boot/boot.bin: boot/boot.asm
	cd boot && ${AS} -f bin -o ../$@ boot.asm

dist/boot/entry.o: boot/entry.asm
	${AS} ${ASFLAGS} -o $@ $^

dist/kernel/kernel.bin: dist/boot/entry.o ${OBJ}
	${LD} ${LDFLAGS_BIN} -o $@ $^

dist/kernel.elf: dist/boot/entry.o ${OBJ}
	${LD} ${LDFLAGS} -o $@ $^

dist/kernel/%.o: %.c ${HEADERS}
	${CC} ${CFLAGS} -o $@ -c $<

dist/MiniOS.img: dist/boot/boot.bin dist/kernel/kernel.bin
	kernel_size_bytes=$(shell wc -c < dist/kernel/kernel.bin); \
	kernel_size_sectors=$$(( ($$kernel_size_bytes + 511) / 512 )); \
	printf %02x $$kernel_size_sectors | xxd -r -p | dd of=dist/boot/boot.bin bs=1 seek=2 count=1 conv=notrunc;
	cat $^ > $@;

clean:
	@rm -rf dist

run: dist/MiniOS.img
	@${QEMU} -drive format=raw,file=$^

# Run QEMU with GDB
debug: dist/MiniOS.img dist/kernel.elf
	@${QEMU} -drive format=raw,file=dist/MiniOS.img -s -S & ${GDB} -ex "target remote localhost:1234" -ex "symbol-file dist/kernel.elf"
