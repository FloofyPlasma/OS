ASM ?= nasm
BUILD_DIR ?= ../../../build

CC ?= i686-elf-gcc
LD ?= i686-elf-ld

ASMFLAGS += -f elf
CFLAGS += -ffreestanding -nostdlib
LIBS += 
LDFLAGS += -T linker.ld -nostdlib

SOURCES_C = $(wildcard *.c)
SOURCES_ASM = $(wildcard *.asm)

OBJECTS_C = $(patsubst %.c, $(BUILD_DIR)/boot/stage2/c/%.o, $(SOURCES_C))
OBJECTS_ASM = $(patsubst %.asm, $(BUILD_DIR)/boot/stage2/asm/%.o, $(SOURCES_ASM))

.PHONY: all clean

all: $(BUILD_DIR)/boot/stage2/stage2.bin

$(BUILD_DIR)/boot/stage2/stage2.bin: $(OBJECTS_C) $(OBJECTS_ASM)
	mkdir -p $(BUILD_DIR)/boot/stage2
	$(LD) $(LDFLAGS) $(LIBS) -Map=$(BUILD_DIR)/boot/stage2/stage2.map -o $@ $^ 

$(BUILD_DIR)/boot/stage2/c/%.o: %.c
	mkdir -p $(BUILD_DIR)/boot/stage2/c/
	$(CC) $(CFLAGS) -c -o $@ $<

$(BUILD_DIR)/boot/stage2/asm/%.o: %.asm
	mkdir -p $(BUILD_DIR)/boot/stage2/asm/
	$(ASM) $(ASMFLAGS) -o $@ $<

clean:
	rm -r $(BUILD_DIR)/boot/stage2