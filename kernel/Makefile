CC = gcc
GDB = gdb
LD = ld
ASM = nasm

OUT_DIR = dist

INCLUDE = -Iinclude
C_SRC = $(wildcard src/*.c)
ASM_SRC = $(wildcard *.asm)

CCFLAGS = -c -ffreestanding -g
LDFLAGS = -Ttext 0x8200
LDFLAGS_BIN = ${LDFLAGS} --oformat binary
ASMFLAGS = -f elf64

all: directories kernel.bin kernel.elf

directories:
	@mkdir -p $(OUT_DIR)

kernel.bin: $(OUT_DIR)/kernel.o $(OUT_DIR)/entry.o
	@echo "===Linking kernel==="
	${LD} ${LDFLAGS} -o ${OUT_DIR}/$@ $^

kernel.elf : $(OUT_DIR)/kernel.o $(OUT_DIR)/entry.o
	@echo "===Linking kernel==="
	${LD} ${LDFLAGS} -o ${OUT_DIR}/$@ $^

$(OUT_DIR)/%.o: src/%.c
	@echo "===Compiling $<==="
	${CC} ${CCFLAGS} ${INCLUDE} -o $@ $<

$(OUT_DIR)/entry.o: entry.asm
	@echo "===Assembling $<==="
	${ASM} ${ASMFLAGS} -o $@ $<

clean:
	rm -f ${OUT_DIR}/*