ASM = nasm

SRC_DIR = src
BUILD_DIR = build

$(BUILD_DIR)/main.img: $(SRC_DIR)/boot/stage1/stage1.asm
	mkdir -p $(BUILD_DIR)/boot/stage1
	dd if=/dev/zero of=$(BUILD_DIR)/main.img bs=512 count=65536
	mkfs.fat -F 16 $(BUILD_DIR)/main.img
	$(ASM) $(SRC_DIR)/boot/stage1/stage1.asm -f bin -o $(BUILD_DIR)/boot/stage1/stage1.bin
	dd if=$(BUILD_DIR)/boot/stage1/stage1.bin of=$(BUILD_DIR)/main.img conv=notrunc

qemu: $(BUILD_DIR)/main.img
	qemu-system-x86_64 -drive file=$(BUILD_DIR)/main.img,format=raw -monitor telnet:127.0.0.1:1234,server,nowait

clean:
	rm -r $(BUILD_DIR)