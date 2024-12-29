CC = gcc
BUILD_DIR ?= ../build

.PHONY: all clean

all: $(BUILD_DIR)/utils/fat

$(BUILD_DIR)/utils/fat:fat.c
	mkdir -p $(BUILD_DIR)/utils
	$(CC) -g -o $@ $<

clean:
	rm -r $(BUILD_DIR)/utils