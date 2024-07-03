# Compiler and assembler tools
CC = gcc
LD = ld
ASM = nasm

# Compilation flags
CCFLAGS = -c -ffreestanding -ggdb
LDFLAGS = -T kernel.ld
LDFLAGS_BIN = ${LDFLAGS} --oformat binary
ASMFLAGS = -f elf64

# Directories
BOOT_DIR = boot
KERNEL_DIR = kernel
DIST_DIR = dist
BOOT_DIST_DIR = $(DIST_DIR)/$(BOOT_DIR)
KERNEL_DIST_DIR = $(DIST_DIR)/$(KERNEL_DIR)

# Boot files
BOOT_SRC = boot.asm

# Kernel files
INCLUDE = -I$(KERNEL_DIR)/include
C_SRC = $(wildcard $(KERNEL_DIR)/src/*.c)
ENTRY_SRC = $(KERNEL_DIR)/entry.asm

.PHONY: all clean run debug

all: clean directories boot.bin kernel.bin kernel.elf MiniOS.img

# Create output directories if they don't exist
directories:
	@echo "\n============ Creating directories ============"
	mkdir -p $(DIST_DIR)
	mkdir -p $(BOOT_DIST_DIR)
	mkdir -p $(KERNEL_DIST_DIR)

# Build bootloader
boot.bin: $(BOOT_DIR)/$(BOOT_SRC)
	@echo "\n============ Building bootloader ============="
	cd $(BOOT_DIR) && ${ASM} -f bin -o ../$(BOOT_DIST_DIR)/$@ $(BOOT_SRC)

# Build kernel
kernel.bin: $(KERNEL_DIST_DIR)/entry.o $(KERNEL_DIST_DIR)/kernel.o
	@echo "\n============= Linking bin kernel ============="
	${LD} ${LDFLAGS_BIN} -o $(KERNEL_DIST_DIR)/$@ $^

kernel.elf: $(KERNEL_DIST_DIR)/entry.o $(KERNEL_DIST_DIR)/kernel.o
	@echo "\n============= Linking elf kernel ============="
	${LD} ${LDFLAGS} -o $(DIST_DIR)/$@ $^

$(KERNEL_DIST_DIR)/%.o: $(C_SRC)
	@echo "\n============== Compiling kernel =============="
	${CC} ${CCFLAGS} ${INCLUDE} -o $@ $<

$(KERNEL_DIST_DIR)/entry.o: $(ENTRY_SRC)
	@echo "\n============== Assembling entry =============="
	${ASM} ${ASMFLAGS} -o $@ $^

# Create final OS image
MiniOS.img: boot.bin kernel.bin
	@echo "\n================ Making image ================"
	kernel_size_bytes=$(shell wc -c < $(KERNEL_DIST_DIR)/kernel.bin); \
	kernel_size_sectors=$$(( ($$kernel_size_bytes + 511) / 512 )); \
	printf %02x $$kernel_size_sectors | xxd -r -p | dd of=$(BOOT_DIST_DIR)/boot.bin bs=1 seek=2 count=1 conv=notrunc;
	cat $(BOOT_DIST_DIR)/boot.bin $(KERNEL_DIST_DIR)/kernel.bin > $(DIST_DIR)/MiniOS.img;
	@echo "\nBuild finished successfully\n"

# Clean build artifacts
clean:
	@echo "\n============== Cleaning binary ==============="
	rm -rf $(DIST_DIR)/*
	rm -rf $(BOOT_DIST_DIR)/dist/*
	rm -rf $(KERNEL_DIST_DIR)/dist/*

# Run QEMU
run: $(DIST_DIR)/MiniOS.img
	@echo "\n=============== Running image ================"
	qemu-system-x86_64 -drive format=raw,file=$^

# Run QEMU with GDB
debug: $(DIST_DIR)/MiniOS.img $(DIST_DIR)/kernel.elf
	@echo "\n=============== Debuging image ==============="
	qemu-system-x86_64 -drive format=raw,file=$(DIST_DIR)/MiniOS.img -s -S & gdb -ex "target remote localhost:1234" -ex "symbol-file $(DIST_DIR)/kernel.elf"
