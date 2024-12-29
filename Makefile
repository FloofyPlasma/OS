ASM = nasm
CC = i686-elf-gcc
LD = i686-elf-ld

SRC_DIR = src
BUILD_DIR = $(shell realpath build)
BOOT_DIR = $(SRC_DIR)/boot
UTIL_DIR = utils

.PHONY: all clean qemu utils stage1 stage2

all: utils $(BUILD_DIR)/main.img

$(BUILD_DIR)/main.img: stage1 stage2
	mkdir -p $(BUILD_DIR)
	dd if=/dev/zero of=$(BUILD_DIR)/main.img bs=512 count=65535
	mkfs.fat -F 16 $(BUILD_DIR)/main.img
	dd if=$(BUILD_DIR)/boot/stage1/stage1.bin of=$(BUILD_DIR)/main.img conv=notrunc
	mcopy -i $(BUILD_DIR)/main.img $(BUILD_DIR)/boot/stage2/stage2.bin "::stage2.bin"

stage1:
	$(MAKE) -C $(BOOT_DIR)/stage1 BUILD_DIR=$(BUILD_DIR)

stage2:
	$(MAKE) -C $(BOOT_DIR)/stage2 BUILD_DIR=$(BUILD_DIR) CC=$(CC) LD=$(LD)

utils:
	$(MAKE) -C $(UTIL_DIR) BUILD_DIR=$(BUILD_DIR)

qemu: all
	qemu-system-x86_64 -drive file=$(BUILD_DIR)/main.img,format=raw -monitor telnet:127.0.0.1:1234,server,nowait

clean:
	$(MAKE) -C $(BOOT_DIR)/stage1 clean
	$(MAKE) -C $(BOOT_DIR)/stage2 clean
	$(MAKE) -C $(UTIL_DIR) clean
	rm -rf $(BUILD_DIR)