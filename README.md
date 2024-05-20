# Systems Programming Assignment 1

## Overview

This project is part of an assessment for a Systems Programming module, focused on developing programs using 16-bit x86 assembler language. The objective is to extend a boot loader with code to display the contents of sectors on a disk image.

## Assessment Content

The solution for the assignment achieves the following:
- **User Input for Sector Number**: Ask the user to enter the number of the sector they want to read.
- **Display Sector Contents**: Display the contents of the specified sector in both hexadecimal and ASCII characters. Each line starts with the offset into the sector (displayed as a 4-digit hex number).
- **Scrolling Display**: Display a smaller number of lines at a time (e.g., 16 lines) and pause until the user presses a key, then continue displaying the next set of lines.
- **Repeat User Input**: After displaying a sector, ask the user for another sector number to display.
- **Multiple Sectors**: Allow the user to enter the number of sectors they wish to display, starting from a specified sector number.

## Project Structure

The project includes the following files:

### bootasm.S
This file contains the initial boot loader code in 16-bit assembly language. It includes:
- **BIOS Console Write Functions**: Functions to write characters and strings to the console using BIOS interrupts.
- **Real Start Function**: The main entry point for the boot loader, setting up segment registers, displaying boot messages, and loading sectors from the disk.
- **Sector Display Functions**: Functions to display sector contents in hexadecimal and ASCII, including offset calculations and user input handling.

### bootasm2.S
This file extends the boot loader with additional functionality to:
- **Read Multiple Sectors**: Ask the user for the number of sectors to display and handle displaying them.
- **Input Validation and Error Handling**: Validate user input for sector numbers and handle errors gracefully.
- **Hexadecimal and ASCII Display**: Display sector contents in both formats, with proper formatting and spacing.

### Makefile
This file contains the instructions to build the boot loader from the assembly source files. It specifies the compiler options and the linking process required to create the bootable disk image.

### sign.pl
A Perl script used to sign the bootable disk image. This script ensures that the image is properly formatted and includes the necessary boot signatures.

## How to Run the Project

### Prerequisites
- A terminal or command prompt on your system.
- NASM assembler installed.
- QEMU or another emulator to test the boot loader.

### Screeshot of Usage
![image](https://github.com/sys-MWell/systems-programming-x86-assembler-language/assets/74254544/38bcb597-280c-42ad-bcde-d83a7ab6ee6f)
![image](https://github.com/sys-MWell/systems-programming-x86-assembler-language/assets/74254544/a616cc71-1aaa-4013-9c75-201bf13e06d1)


