ASM ?= nasm
BUILD_DIR ?= ../../../build

.PHONY: all clean

all: $(BUILD_DIR)/boot/stage1/stage1.bin

$(BUILD_DIR)/boot/stage1/stage1.bin: stage1.asm
	mkdir -p $(BUILD_DIR)/boot/stage1
	$(ASM) -o $@ -f bin $<

clean:
	rm -r $(BUILD_DIR)/boot/stage1