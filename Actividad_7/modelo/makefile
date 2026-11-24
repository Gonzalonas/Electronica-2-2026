
BUILD_DIR = build
SRC_DIR = src

all: $(BUILD_DIR)/alu.o $(BUILD_DIR)/main.o | $(BUILD_DIR) 
	gcc $(BUILD_DIR)/alu.o $(BUILD_DIR)/main.o -o $(BUILD_DIR)/model_alu

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c | $(BUILD_DIR)
	gcc -c -Wall -Wextra  $(<) -o $(@)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)
