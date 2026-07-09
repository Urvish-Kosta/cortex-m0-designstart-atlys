# ==============================================================================
# Firmware Makefile -- Cortex-M0 DesignStart demonstrator
#
# Builds with the GNU Arm Embedded toolchain (arm-none-eabi-gcc). The original
# project used Keil MDK; a uVision project can drive the same sources, but this
# Makefile keeps the build reproducible with free tools.
#
# Targets:
#   make            -> build/firmware.elf, .bin, .hex (VHDL memory init format)
#   make clean      -> remove build artefacts
#
# Author: Urvish Kosta
# License: MIT (see LICENSE at repository root)
# ==============================================================================

CROSS   ?= arm-none-eabi-
CC      := $(CROSS)gcc
OBJCOPY := $(CROSS)objcopy
SIZE    := $(CROSS)size

BUILD   := build
TARGET  := $(BUILD)/firmware

SRCS_C  := src/main.c src/uart.c src/demo_tasks.c
SRCS_S  := src/startup.S

CFLAGS  := -mcpu=cortex-m0 -mthumb -Os -g \
           -ffunction-sections -fdata-sections \
           -Wall -Wextra -Werror \
           -Iinclude
LDFLAGS := -mcpu=cortex-m0 -mthumb -nostdlib -nostartfiles \
           -Wl,--gc-sections -T link.ld

OBJS := $(patsubst src/%.c,$(BUILD)/%.o,$(SRCS_C)) \
        $(patsubst src/%.S,$(BUILD)/%.o,$(SRCS_S))

.PHONY: all clean size

all: $(TARGET).elf $(TARGET).bin $(TARGET).hex size

$(BUILD):
	mkdir -p $(BUILD)

$(BUILD)/%.o: src/%.c | $(BUILD)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD)/%.o: src/%.S | $(BUILD)
	$(CC) $(CFLAGS) -c $< -o $@

$(TARGET).elf: $(OBJS) link.ld
	$(CC) $(LDFLAGS) $(OBJS) -lgcc -o $@

$(TARGET).bin: $(TARGET).elf
	$(OBJCOPY) -O binary $< $@

# One 32-bit little-endian word per line, hex -- the format ahb_mem.vhd loads.
$(TARGET).hex: $(TARGET).bin
	python3 ../scripts/bin2hex.py $< $@

size: $(TARGET).elf
	$(SIZE) $<

clean:
	rm -rf $(BUILD)
