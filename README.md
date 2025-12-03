# DA14531 Custom Makefile Build
This repository provides a minimal Makefile-based build system for the Renesas DA14531 using SDK version 6.0.24.1464.
It allows you to build firmware (.elf, .hex, .bin, .img) without needing e²studio.

Two toolchains are supported:  
- **GCC** (main branch), tested with the official Renesas blinky example.  
- **LLVM/Clang** (separate branch), tested with the official Renesas BLE App Sleep Mode example.

## 1. Why this Makefile?
The official Renesas SDK is designed for use with e²studio (Eclipse-based IDE). While e²studio works, I chose to create my own Makefile for the following reasons:
### My main reasons
1. Easier integration with projects - Being independent from e²studio provides better version control for my projects.
2. LLVM compiler issues – the LLVM e²studio flow always gave a busybox error on Windows, and I could only build successfully using e²studio on Linux.
3. Simpler path management – with Makefiles, adding or modifying include paths is straightforward. e²studio generates very complex Makefiles automatically, which are harder to fine-tune.
### Additional benefits of this Makefile approach
1. It's lightweight. You can use a code editor of your choice instead of needing to download the e²Studio IDE.
2. It's portable. Works in MSYS2 (Windows) or Linux with make + arm-none-eabi-gcc.
3. All compiler/linker flags are visible and editable.
### Why you might still use e²studio
- Built-in debugger support (SEGGER J-Link, breakpoints, variable watch).
- Project wizards and templates for quick setup.
- GUI project management (no manual Makefile editing).
- Official Renesas documentation is mostly tailored to e²studio users.

In short:
- If you want a minimal, script-driven workflow, this Makefile is for you.
- If you prefer a feature-rich IDE with debugging tools, stick to e²studio.

## 2. Notes / Tips
- **Base Makefile:** This Makefile serves as a starting point. You may need to modify it for other examples or to integrate additional features.
- **VSCode Integration:** I  personally use Visual Studio Code with modified ```c_cpp_properties.json``` and ```settings.json``` files. These files enable IntelliSense across all SDK files, which helps speed up development. I may share them in the future if possible.
- **MinGW64 VSCode Integration:** It is possible to integrate MinGW64 with VSCode, allowing the entire development workflow to be handled within VSCode without needing separate MinGW64 consoles.
- **Caveats:** Some important caveats and startup considerations for the DA14531 are discussed in [Section 5: Minor Code Modifications](#5-minor-code-modifications).

## 3. Requirements
- arm-none-eabi-gcc (version tested: 10.3.1.20210824)
- MSYS2/MinGW64 or Linux shell
- Renesas DA145xx SDK (version tested: 6.0.24.1464)

## 4. Folder Structure
This structure is meant to match the Renesas examples.
```
project_root/
├── Makefile
└── src/
    ├── main.c
    ├── platform/
    │   └── user_periph_setup.c
    └── config/
        ├── da1458x_config_basic.h
        ├── da1458x_config_advanced.h
        ├── da14531_config_basic.h
        ├── da14531_config_advanced.h
        ├── user_periph_setup.h
        └── user_profiles_config.h
```
The ```main``` and ```user_periph_setup``` files can be found in the blinky example project. All the config files can be found in the empty_peripheral_template example project.

## 5. Minor Code Modifications
### 1. Ensure peripheral initialization in production mode
By default, ```system_init()``` calls ```periph_init()```, but in production builds this can be skipped unless explicitly enabled. To fix this, in ```da14531_config_advanced.h``` add:
```c
#define CFG_PRODUCTION_DEBUG_OUTPUT
```
This ensures ```periph_init()``` is executed as expected.

Also, add the following lines to ```user_periph_init.h```:
```c
#define PRODUCTION_DEBUG_PORT   GPIO_PORT_0
#define PRODUCTION_DEBUG_PIN    GPIO_PIN_5
```
This UART is needed by the ```hardfault_handler.c``` file when we do ```#define CFG_PRODUCTION_DEBUG_OUTPUT```.
### 2. Handle the watchdog timer
In production mode, the watchdog runs by default, as it is defined in the ```da14531_config_advanced.h``` example code provided by Renesas. If not handled, it will reset the chip.
There are two options:
#### Option 1: Disable watchdog permanently
In ```da14531_config_basic.h```, modify/add:
```c
#undef CFG_WDOG
```
Then modify ```main.c``` as follows:
```c
    ...
    system_init();
    while ((GetWord16(SYS_STAT_REG) & XTAL32M_SETTLED) == 0); // Required. Otherwise, DA14531 may get stuck in a bootloop
    blinky_test();
    ...
```
> **Note:** The line checking ```XTAL32M_SETTLED``` is critical. Omitting it can cause the chip to hang at startup.
#### Option 2: Freeze watchdog at runtime by adding the following in ```main.c```:
```c
#include "arch_wdg.h"

    ...
    system_init();
    arch_asm_delay_us(10); // Required. Otherwise, DA14531 may get stuck in a bootloop
    wdg_freeze();
    while ((GetWord16(SYS_STAT_REG) & XTAL32M_SETTLED) == 0); // Required. Otherwise, DA14531 may get stuck in a bootloop
    blinky_test();
    ...
```
> **Note:** Both the ```arch_asm_delay_us(10)``` and ```XTAL32M_SETTLED``` checks are necessary to prevent bootlooping when freezing the watchdog.
### 3. Prevent unintended resets on P0_0 (HW reset pin) (For DA14531MOD or similar designs)
On the DA14531MOD and similar designs using external SPI flash, P0_0 defaults to a hardware reset pin. However, it is also connected to the SPI flash MOSI pin.
If you are using the flash to store code or data, you must disable the hardware reset function on P0_0. Do this at the beginning of the ```periph_init()``` function in ```user_periph_setup.c```:
```c
// Disable HW RST on P0_0 (conflicts with SPI flash MOSI)
GPIO_Disable_HW_Reset();
```
Without this change, the SPI flash activity may inadvertently trigger resets. 

**NOTE:** With hardware reset disabled, you cannot reset the module via P0_0. If you need to reprogram the module later on and are having trouble connecting, follow this procedure after reviewing [Section 7: Flashing](#7-flashing) for full details:
1. Disconnect the USB-to-UART module.
2. Hold down the reset button.
3. Reconnect the USB.
4. Press **Connect** in SmartSnippets Toolbox.
5. Release the reset button when you see "Please press the hardware reset button on the board to start the download process."
> Make sure to read [Section 7: Flashing](#7-flashing), so you understand the full flashing process before attempting these steps.

## 6. Setup Instructions
- Clone the makefile into your project.
- Run ```export SDK_ROOT=/path/to/DA145xx_SDK/6.0.24.1464``` before building (or edit it inside the Makefile).
- Run ```make```.

This will generate the following in the build/ folder:
- blinky.elf
- blinky.hex
- blinky.bin
- blinky.img
- blinky.map

## 7. Flashing
I used the Renesas SmartSnippets Toolbox for flashing the DA14531MOD SPI flash via the one-wire UART.

### General steps:
1. Open SmartSnippets Toolbox.
2. Select the COM port connected to the DA14531 (via UART or JTAG).
3. Go to **Configurator > Board Setup**. Modify the settings according to your setup.
   - Example tested settings:  
     - UART TX = P0_5, UART RX = P0_5, Baud = 115200  
     - SPI-CLK = P0_4  
     - SPI-CS  = P0_1  
     - SPI-MISO = P0_3  
     - SPI-MOSI = P0_0  
4. Go to **Programmer > Flash Code**. Import either your `.hex` or `.img` file as a non-modified bootable file.
   - `.hex` = common format used by Renesas for downloadable sample/demo applications (sample hex files can be downloaded via Renesas Flash Programmer tool) 
   - `.img` = generated with `mkimage`, also supported for flashing
5. **Connect** to your device, then select **Burn**. If prompted, it is always recommended to erase and burn.

## 8. License
This repository (Makefile, README, and related documentation) is licensed under the **MIT License**.  
See the [LICENSE](./LICENSE) file for details.

## 9. Disclaimer
This repository does not include any Renesas DA145xx SDK files.  
To build and flash projects, please download the official SDK from the Renesas website.
   
