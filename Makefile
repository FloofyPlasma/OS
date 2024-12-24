ASM = nasm

SRC_DIR = src
BUILD_DIR = build

$(BUILD_DIR)/main.img: $(SRC_DIR)/main.asm
	mkdir -p $(BUILD_DIR)
	dd if=/dev/zero of=$(BUILD_DIR)/main.img bs=512 count=2800
	$(ASM) $(SRC_DIR)/main.asm -f bin -o $(BUILD_DIR)/main.bin
	dd if=$(BUILD_DIR)/main.bin of=$(BUILD_DIR)/main.img conv=notrunc