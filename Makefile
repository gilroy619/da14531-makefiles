# ================================================================
# LLVM Makefile for DA14531 BLE App Sleep Mode Project
#
# Copyright (c) 2025 gilroy619
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# ================================================================
#
# Environment:
#   - Tested with MSYS2 MINGW64
#   - LLVM/Clang: LLVMEmbeddedToolchainForArm-17.0.1-Windows-x86_64 (Provided with e2 studio)
#   - Renesas DA145xx SDK: v6.0.24.1464
#
# Usage:
#   make            # Build ELF, HEX, BIN, IMG
#   make clean      # Remove build artifacts
#
# Configuration:
#   - Set SDK_ROOT before building:
#       export SDK_ROOT=/path/to/DA145xx_SDK/6.0.24.1464   (Linux/MSYS)
#   - Or edit the SDK_ROOT variable directly in this Makefile
#
#   - Set LLVM_BIN before building:
#       export LLVM_BIN=/path/to/llvm_arm/LLVMEmbeddedToolchainForArm-17.0.1-Windows-x86_64/bin   (MSYS)
#     Or edit the LLVM_BIN variable directly in this Makefile
#
# Notes:
#   - Requires ARM GCC toolchain in PATH
#   - Generates .elf, .hex, .bin, .img, and .map files
# ================================================================

PROJECT_ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
SDK_ROOT ?= /path/to/DA145xx_SDK/6.0.24.1464
BUILD_DIR := build
LLVM_BIN ?= /path/to/llvm_arm/LLVMEmbeddedToolchainForArm-17.0.1-Windows-x86_64/bin

# Toolchain
CC := $(LLVM_BIN)/clang.exe 
LD := $(LLVM_BIN)/clang.exe 
AR := $(LLVM_BIN)/llvm-ar.exe 
OBJCOPY := arm-none-eabi-objcopy
OBJDUMP := $(LLVM_BIN)/llvm-objdump.exe

# Project name 
PROJECT := ble_app_sleep_mode

# Targets
TARGET  := $(BUILD_DIR)/$(PROJECT).elf
HEX     := $(BUILD_DIR)/$(PROJECT).hex
BIN     := $(BUILD_DIR)/$(PROJECT).bin
IMG     := $(BUILD_DIR)/$(PROJECT).img
MAP     := $(BUILD_DIR)/$(PROJECT).map

# Include platform and common related files for compiler
INCLUDE_DIRS := $(SDK_ROOT)/sdk/platform/arch/main \
				$(SDK_ROOT)/sdk/platform/include \
				$(SDK_ROOT)/sdk/platform/include/CMSIS/5.9.0/CMSIS/Core/Include \
				$(SDK_ROOT)/sdk/platform/arch \
				$(SDK_ROOT)/sdk/platform/arch/boot \
				$(SDK_ROOT)/sdk/platform/arch/compiler \
				$(SDK_ROOT)/sdk/platform/arch/ll \
				$(SDK_ROOT)/sdk/platform/system_library/include \
				$(SDK_ROOT)/sdk/platform/core_modules/nvds/api \
				$(SDK_ROOT)/sdk/platform/core_modules/rf/api \
				$(SDK_ROOT)/sdk/platform/core_modules/rwip/api \
				$(SDK_ROOT)/sdk/platform/core_modules/common/api \
				$(SDK_ROOT)/sdk/platform/core_modules/gtl/src \
				$(SDK_ROOT)/sdk/platform/core_modules/gtl/api \
				$(SDK_ROOT)/sdk/platform/core_modules/dbg/api \
				$(SDK_ROOT)/sdk/platform/core_modules/h4tl/api \
				$(SDK_ROOT)/sdk/platform/core_modules/ke/api \
				$(SDK_ROOT)/sdk/platform/core_modules/ke/src \
				$(SDK_ROOT)/sdk/platform/core_modules/arch_console \
				$(SDK_ROOT)/sdk/platform/driver/gpio \
				$(SDK_ROOT)/sdk/platform/driver/uart \
				$(SDK_ROOT)/sdk/platform/driver/dma \
				$(SDK_ROOT)/sdk/platform/driver/syscntl \
				$(SDK_ROOT)/sdk/platform/driver/hw_otpc \
				$(SDK_ROOT)/sdk/platform/driver/adc \
				$(SDK_ROOT)/sdk/platform/driver/trng \
				$(SDK_ROOT)/sdk/platform/driver/wkupct_quadec \
				$(SDK_ROOT)/sdk/platform/driver/ble \
				$(SDK_ROOT)/sdk/platform/driver/reg \
				$(SDK_ROOT)/sdk/platform/driver/timer \
				$(SDK_ROOT)/sdk/platform/driver/systick \
				$(SDK_ROOT)/sdk/platform/utilities/otp_cs \
				$(SDK_ROOT)/sdk/platform/utilities/otp_hdr \
				$(SDK_ROOT)/sdk/common_project_files \
				$(SDK_ROOT)/third_party/rand \
				$(SDK_ROOT)/third_party/irng \
				$(SDK_ROOT)/third_party/hash \
				$(SDK_ROOT)/third_party/rand

# Include ble_stack related files
INCLUDE_DIRS += $(SDK_ROOT)/sdk/ble_stack/rwble \
				$(SDK_ROOT)/sdk/ble_stack/rwble_hl \
				$(SDK_ROOT)/sdk/ble_stack/profiles \
				$(SDK_ROOT)/sdk/ble_stack/profiles/custom \
				$(SDK_ROOT)/sdk/ble_stack/profiles/custom/custs/api \
				$(SDK_ROOT)/sdk/ble_stack/ea/api \
				$(SDK_ROOT)/sdk/ble_stack/em/api \
				$(SDK_ROOT)/sdk/ble_stack/hci/api \
				$(SDK_ROOT)/sdk/ble_stack/host/att \
				$(SDK_ROOT)/sdk/ble_stack/host/att/attm \
				$(SDK_ROOT)/sdk/ble_stack/host/att/atts \
				$(SDK_ROOT)/sdk/ble_stack/host/att/attc \
				$(SDK_ROOT)/sdk/ble_stack/host/gap \
				$(SDK_ROOT)/sdk/ble_stack/host/gap/gapc \
				$(SDK_ROOT)/sdk/ble_stack/host/gap/gapm \
				$(SDK_ROOT)/sdk/ble_stack/host/smp \
				$(SDK_ROOT)/sdk/ble_stack/host/smp/smpm \
				$(SDK_ROOT)/sdk/ble_stack/host/smp/smpc \
				$(SDK_ROOT)/sdk/ble_stack/host/gatt \
				$(SDK_ROOT)/sdk/ble_stack/host/gatt/gattc \
				$(SDK_ROOT)/sdk/ble_stack/host/gatt/gattm \
				$(SDK_ROOT)/sdk/ble_stack/host/l2c/l2cc \
				$(SDK_ROOT)/sdk/ble_stack/controller/llm \
				$(SDK_ROOT)/sdk/ble_stack/controller/llc \
				$(SDK_ROOT)/sdk/ble_stack/controller/lld \
				$(SDK_ROOT)/sdk/ble_stack/controller/em

# Include app_module related files
INCLUDE_DIRS += $(SDK_ROOT)/sdk/app_modules/api 

# Library directories for linker
LIB_DIRS := $(SDK_ROOT)/sdk/common_project_files/misc \
			$(SDK_ROOT)/sdk/platform/system_library/output/IAR


# ----------------------------------------------------------------
# Compiler / Linker flags
# ----------------------------------------------------------------
DEFS = -D__DA14531__

CFLAGS = -target arm-none-eabi \
		 -mcpu=cortex-m0plus -march=armv6-m -mthumb \
		 -Os -fmessage-length=0 -fsigned-char \
		 -ffunction-sections -fdata-sections -Wall \
		 -Isrc \
		 -Isrc/config \
		 -Isrc/custom_profile \
		 $(addprefix -I,$(INCLUDE_DIRS)) \
		 -include "src/config/da1458x_config_basic.h" \
		 -include "src/config/da1458x_config_advanced.h" \
		 -include "src/user_app.h" \
		 -include "$(SDK_ROOT)/sdk/app_modules/api/app_user_config.h" \
		 $(DEFS)
	
# LD Script src and final location
LDSCRIPT_SRC := $(SDK_ROOT)/sdk/common_project_files/ldscripts/ldscript_DA14531_e2s.lds.S
LDSCRIPT     := $(PROJECT_ROOT)ldscript_DA14531.lds

# LD Script pre-processing defines and directories
LDSCRIPT_DEFS := -D__DA14531__ 

LDSCRIPT_INCS := -I$(PROJECT_ROOT)/src/config \
    			 -I$(SDK_ROOT)/sdk/common_project_files \
    			 -I$(SDK_ROOT)/sdk/common_project_files/misc

# LD script post process flags/ .map file generation
LDFLAGS = -target arm-none-eabi \
		  -mcpu=cortex-m0plus -march=armv6-m -mthumb -Os \
          -fsigned-char -ffunction-sections -fdata-sections -Wall \
		  -T $(LDSCRIPT) \
		  -Wl,--gc-sections \
		  $(addprefix -L,$(LIB_DIRS)) \
		  -Wl,-Map,$(MAP) \
		  -l:da14531.a

# ----------------------------------------------------------------
# Source files: app + required SDK platform files
# ----------------------------------------------------------------
SRC_C := src/llvm_crt.c \
	     src/custom_profile/user_custs1_def.c \
		 src/custom_profile/user_custs_config.c \
		 src/platform/user_periph_setup.c \
		 src/user_sleepmode.c \
		 src/user_sleepmode_task.c \
		 $(SDK_ROOT)/sdk/app_modules/src/app_bass/app_bass.c \
		 $(SDK_ROOT)/sdk/app_modules/src/app_bass/app_bass_task.c \
		 $(SDK_ROOT)/sdk/ble_stack/profiles/custom/custom_common.c \
		 $(SDK_ROOT)/sdk/ble_stack/profiles/custom/custs/src/custs1.c \
		 $(SDK_ROOT)/sdk/ble_stack/profiles/custom/custs/src/custs1_task.c \
		 $(SDK_ROOT)/sdk/ble_stack/profiles/prf.c \
		 $(SDK_ROOT)/sdk/ble_stack/profiles/prf_utils.c \
		 $(SDK_ROOT)/sdk/platform/driver/adc/adc_531.c \
		 $(SDK_ROOT)/sdk/platform/driver/dma/dma.c \
		 $(SDK_ROOT)/sdk/platform/driver/gpio/gpio.c \
		 $(SDK_ROOT)/sdk/platform/driver/hw_otpc/hw_otpc_531.c \
		 $(SDK_ROOT)/sdk/platform/driver/syscntl/syscntl.c \
		 $(SDK_ROOT)/sdk/platform/driver/timer/timer0.c \
		 $(SDK_ROOT)/sdk/platform/driver/trng/trng.c \
		 $(SDK_ROOT)/third_party/rand/chacha20.c \
		 $(SDK_ROOT)/sdk/platform/driver/uart/uart.c \
		 $(SDK_ROOT)/sdk/platform/driver/uart/uart_utils.c \
		 $(SDK_ROOT)/sdk/platform/driver/wkupct_quadec/wkupct_quadec.c \
		 $(SDK_ROOT)/sdk/platform/driver/systick/systick.c \
		 $(SDK_ROOT)/sdk/platform/arch/main/hardfault_handler.c \
		 $(SDK_ROOT)/sdk/platform/arch/main/nmi_handler.c \
		 $(SDK_ROOT)/sdk/platform/arch/boot/startup_DA14531.c \
		 $(SDK_ROOT)/sdk/platform/arch/boot/system_DA14531.c \
		 $(SDK_ROOT)/sdk/platform/core_modules/rf/src/ble_arp.c \
		 $(SDK_ROOT)/sdk/platform/core_modules/rf/src/rf_531.c \
		 $(SDK_ROOT)/sdk/ble_stack/rwble/rwble.c \
		 $(SDK_ROOT)/sdk/platform/core_modules/rwip/src/rwip.c \
		 $(SDK_ROOT)/sdk/platform/core_modules/arch_console/arch_console.c \
		 $(SDK_ROOT)/sdk/platform/arch/main/arch_hibernation.c \
		 $(SDK_ROOT)/sdk/platform/arch/main/arch_main.c \
		 $(SDK_ROOT)/sdk/platform/arch/main/arch_rom.c \
		 $(SDK_ROOT)/sdk/platform/arch/main/arch_sleep.c \
		 $(SDK_ROOT)/sdk/platform/arch/main/arch_system.c \
		 $(SDK_ROOT)/third_party/hash/hash.c \
		 $(SDK_ROOT)/sdk/platform/arch/main/jump_table.c \
		 $(SDK_ROOT)/sdk/platform/core_modules/nvds/src/nvds.c \
		 $(SDK_ROOT)/sdk/platform/utilities/otp_cs/otp_cs.c \
		 $(SDK_ROOT)/sdk/platform/utilities/otp_hdr/otp_hdr.c \
		 $(SDK_ROOT)/sdk/platform/system_library/src/DA14531/system_library_531.c \
		 $(SDK_ROOT)/sdk/app_modules/src/app_common/app.c \
		 $(SDK_ROOT)/sdk/app_modules/src/app_bass/app_bass.c \
		 $(SDK_ROOT)/sdk/app_modules/src/app_bass/app_bass_task.c \
		 $(SDK_ROOT)/sdk/app_modules/src/app_bond_db/app_bond_db.c \
		 $(SDK_ROOT)/sdk/app_modules/src/app_custs/app_customs.c \
		 $(SDK_ROOT)/sdk/app_modules/src/app_custs/app_customs_task.c \
		 $(SDK_ROOT)/sdk/app_modules/src/app_default_hnd/app_default_handlers.c \
		 $(SDK_ROOT)/sdk/app_modules/src/app_easy/app_easy_crypto.c \
		 $(SDK_ROOT)/sdk/app_modules/src/app_easy/app_easy_msg_utils.c \
		 $(SDK_ROOT)/sdk/app_modules/src/app_easy/app_easy_security.c \
		 $(SDK_ROOT)/sdk/app_modules/src/app_easy/app_easy_storage.c \
		 $(SDK_ROOT)/sdk/app_modules/src/app_easy/app_easy_timer.c \
		 $(SDK_ROOT)/sdk/app_modules/src/app_entry/app_entry_point.c \
		 $(SDK_ROOT)/sdk/app_modules/src/app_common/app_msg_utils.c \
		 $(SDK_ROOT)/sdk/app_modules/src/app_sec/app_security.c \
		 $(SDK_ROOT)/sdk/app_modules/src/app_sec/app_security_task.c \
		 $(SDK_ROOT)/sdk/app_modules/src/app_common/app_task.c \
		 $(SDK_ROOT)/sdk/app_modules/src/app_common/app_utils.c 
		 
# Object file
OBJ := $(patsubst %.c,$(BUILD_DIR)/%.o,$(SRC_C))

# MKIMG tool
MKIMAGE := $(SDK_ROOT)/binaries/host/windows/mkimage/mkimage.exe

# ----------------------------------------------------------------
# Rules
# ----------------------------------------------------------------

# Default build target
all: $(TARGET) $(HEX) $(BIN) $(IMG)

# ELF build rule
$(TARGET): $(OBJ) $(LDSCRIPT)
	$(LD) $(OBJ) $(LDFLAGS) -o $@
	
# HEX from ELF
$(HEX): $(TARGET)
	$(OBJCOPY) -O ihex --gap-fill 0xff $< $@

# BIN from ELF
$(BIN): $(TARGET)
	$(OBJCOPY) -O binary $< $@

# IMG from BIN
$(IMG): $(BIN)
	$(MKIMAGE) single $< $(SDK_ROOT)/sdk/platform/include/sdk_version.h $@

# Compile C into BUILD_DIR
$(BUILD_DIR)/%.o: %.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@
	
# Preprocess linker script
$(LDSCRIPT): $(LDSCRIPT_SRC)
	$(CC) -E -P -c $(LDSCRIPT_INCS) $(LDSCRIPT_DEFS) $< -o $@

clean:
	rm -rf $(BUILD_DIR) $(TARGET) $(MAP) $(BIN) $(IMG) $(HEX) $(LDSCRIPT)

.PHONY: all clean
