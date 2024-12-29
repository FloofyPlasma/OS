ASM ?= nasm
BUILD_DIR ?= ../../../build

CC16 ?=/c/WATCOM/binnt64/wcc
CFLAGS16 ?= -4 -d3 -s -wx -ms -zl -zq
LD16 ?=/c/WATCOM/binnt64/wlink

SOURCES_C = $(wildcard *.c)
SOURCES_ASM = $(wildcard *.asm)

OBJECTS_C = $(patsubst %.c, $(BUILD_DIR)/boot/stage2/c/%.o, $(SOURCES_C))
OBJECTS_ASM = $(patsubst %.asm, $(BUILD_DIR)/boot/stage2/asm/%.o, $(SOURCES_ASM))

.PHONY: all clean

all: $(BUILD_DIR)/boot/stage2/stage2.bin

$(BUILD_DIR)/boot/stage2/stage2.bin: $(OBJECTS_C) $(OBJECTS_ASM)
	mkdir -p $(BUILD_DIR)/boot/stage2
	$(LD16) NAME $(BUILD_DIR)/boot/stage2/stage2.bin FILE \{ $(OBJECTS_C) $(OBJECTS_ASM) \} OPTION MAP=$(BUILD_DIR)/boot/stage2/stage2.map @linker.lnk

$(BUILD_DIR)/boot/stage2/c/%.o: %.c
	mkdir -p $(BUILD_DIR)/boot/stage2/c/
	$(CC16) $(CFLAGS16) -fo=$@ $<

$(BUILD_DIR)/boot/stage2/asm/%.o: %.asm
	mkdir -p $(BUILD_DIR)/boot/stage2/asm/
	$(ASM) -o $@ -f obj $<

clean:
	rm -r $(BUILD_DIR)/boot/stage2