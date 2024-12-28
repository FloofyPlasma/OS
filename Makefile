ASM = nasm

SRC_DIR = src
BUILD_DIR = build
UTIL_DIR = utils

.PHONY: clean qemu utils

$(BUILD_DIR)/main.img: $(SRC_DIR)/boot/stage1/stage1.asm
	mkdir -p $(BUILD_DIR)/boot/stage1
	mkdir -p $(BUILD_DIR)/boot/stage2
	dd if=/dev/zero of=$(BUILD_DIR)/main.img bs=512 count=65535
	mkfs.fat -F 16 $(BUILD_DIR)/main.img
	$(ASM) $(SRC_DIR)/boot/stage1/stage1.asm -f bin -o $(BUILD_DIR)/boot/stage1/stage1.bin
	$(ASM) $(SRC_DIR)/boot/stage2/stage2.asm -f bin -o $(BUILD_DIR)/boot/stage2/stage2.bin
	dd if=$(BUILD_DIR)/boot/stage1/stage1.bin of=$(BUILD_DIR)/main.img conv=notrunc
	mcopy -i $(BUILD_DIR)/main.img $(BUILD_DIR)/boot/stage2/stage2.bin "::stage2.bin"

qemu: $(BUILD_DIR)/main.img
	qemu-system-x86_64 -drive file=$(BUILD_DIR)/main.img,format=raw -monitor telnet:127.0.0.1:1234,server,nowait

utils:
	mkdir -p $(BUILD_DIR)/utils
	gcc -g $(UTIL_DIR)/fat.c -o $(BUILD_DIR)/utils/fat

clean:
	rm -r $(BUILD_DIR)