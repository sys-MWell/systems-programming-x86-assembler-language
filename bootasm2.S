# When the PC starts, the processor is essentially emulating an 8086 processor, i.e. 
# a 16-bit processor.  So our initial boot loader code is 16-bit code that will 
# eventually switch the processor into 32-bit mode.

# This code is linked to assume a starting address of 0x7C00 which is where the BIOS
# will load a boot segment.

.code16                         # Assemble for 16-bit mode
.globl start
start:
    jmp     real_start

# Write to the console using BIOS.
# 
# Input: SI contains the address of the null-terminated string to be displayed

cons_write:
    movb    $0x0e, %ah           # 0x0e is the INT 10h BIOS call to output the value contained in AL to screen

cons_write_rpt:
    movb    (%si), %al          # Load the byte at the location contained in the SI register into AL   
    inc     %si                 # Add 1 to the value in SI
    cmp     $0, %al             # Compare the value in AL with 0
    jz      cons_write_done     # If it is zero, then we are done
    int     $0x10               # Output the character in AL to the screen
    jmp     cons_write_rpt      # and continue

cons_write_done:                # Something that is called will never return 
    ret                         # until a 'ret' instruction is encountered.  Labels do 
                                # not give a program any structure.  They just give a 
                                # memory location a name that we can use in our code. 

cons_write_crlf:
    movb    $0x0e, %ah          # Output CR
    movb    $0x0d, %al
    int     $0x10
    movb    $0x0a, %al          # Output LF
    int     $0x10
    ret

cons_writeline:
    call    cons_write
    call    cons_write_crlf
    ret

cons_write_int:
    movw    %bx, %ax                # Move contents of bx into ax
    movw    $intbuffer + 4, %si     #Si used as buffer for pointer, point at end of buffer, last character position

asciidigit:
    xor     %dx, %dx
    movw    $10, %cx        # Division by 10
    div     %cx
    addb    $48, %dl        # Remainder number 0-9 so remainder stored in lower part of dx register, add 48 for ascii character
    movb    %dl, (%si)      # Move content of dl into address pointed to by si
    dec     %si             # Decrement si by 1, moving point forward (back by one towards start)
    cmp     $0, %ax         # Compare result of ax by 0, to know if to finish loop, if not reached zero continue loop
    jne     asciidigit      # Loop (jump) if not equal to 0
    inc     %si             # Increment si by one as we decremented by 1 more than needed
    call    cons_writeline
    ret

intbuffer: 
    .string "     " # Allocated buffer, 5 spaces, buffer used to write characters to


# Display empty character - space
cons_write_spc:
    push    %ax
    movb    $0x0e, %ah          # 0x0e is the INT 10h BIOS call to output the value contained in AL to screen
    movb    $0x20, %al          # 10 hex is ASCII for space character, display to screen
    int     $0x10               # Output the character in AL to the screen
    pop     %ax  
    ret

### -------------------- ###
###          HEX         ###

cons_write_hex_2:
    # If hex is two characters
    movb    (%bx), %al           # Moving from memory to register
    movb    %al, %bh             # Move contents of AL into BH, higher portion on BX register
    subw    $2, %cx              # Only want gap between every 2 hex characters, currently is 4
    jmp     cons_write_hex

cons_write_hex_4:
    # If hex is four characters
    movb    (%bx), %al           # Moving from memory to register  
    jmp     cons_write_hex

cons_write_hex:
    push    %ax                  # Push AX, BX, CX and DX to stack - want to preserve the registers we're using for hex conversion
    push    %bx
    push    %cx
    push    %dx                  
    movb    $0x0e, %ah           # 0x0e is the INT 10h BIOS call to output the value contained in AL to screen
    inc     %dx

hexcharloop:
    rol     $4, %bx              # Shift left by 4, so first 4 bits of binary are now last 4 bits
    movw    %bx, %si             # Move shifted binary to si (source index)
    and     $0x000F, %si         # Logical AND, by 000F, so last 4 bits is the binary number
    movb    hexchar(%si), %al    # Get hex equivalent of binary value
    int     $0x10                # Output the character in AL to the screen
    loop    hexcharloop          # Loop 4 times as moved in CX, for each hex value

    pop     %dx                  # Pop DX, CX, BX and AX from stack in order they were added, unpreserve
    pop     %cx
    pop     %bx                 
    pop     %ax
    call    cons_write_spc       # Display space character
    ret                          # Return when done

hexchar:	.ascii "0123456789ABCDEF"   #Hexadecimal characters

### -------------------- ###

sector_display_offset:                # Display offsets
    push    %bx
    push    %cx
    movw    $16, %bx                  # BX becomes offset number - Initially is max offset for screen 512 byte display
    imul    %dx, %bx                  # Need to get offset, every 16 bytes, so need to times BX which is 16 bytes by dx, e.g. 1 to get 1 x 16 = 16 so offset 16
    movw    $4, %cx                   # CX register used, gap between every 4 hex characters - Loop 4 times as moved in CX, for each hex value - Week 3 example
    call    cons_write_hex_4          # Display offset as HEX
    pop     %cx
    pop     %bx 
    ret

sector_display_hex:                   # Display hexadecimal sector portion
    push    %bx                       # Push BX and CX to stack to preserve
    push    %cx
    movw    $4, %cx                   # CX register used, gap between every 4 hex characters - Loop 4 times as moved in CX, for each hex value - Week 3 example
    call    cons_write_hex_2          # Display hexadecimal values
    pop     %cx                       # Unpreserve CX and BX
    pop     %bx
    inc     %bx                       # Increment BX to go through all bytes in BX - moving to another memory location
    dec     %dx                       # Decrement count for 16 bytes
    cmpw    $0, %dx                   # If all bytes are displayed continue
    jnz     sector_display_hex
    ret

### -------------------- ###
###        ASCII         ###

cons_write_sector_ascii:
    push    %ax
    cmpb    $32, %al                        # Check if decimal character less then 32 - These are not viewable characters - Compared decimal value 32 with AL
    jae     cons_write_sector_ascii_done    # Need to check if the value is less than 32 if is print underscore instead
    movb    $0x5F, %al                      # 5F means underscore, we want to display underscore if decimal is less then 32
    
cons_write_sector_ascii_done:
    movb    $0x0e, %ah                      # 0x0e is the INT 10h BIOS call to output the value contained in AL to screen
    int     $0x10                           # Output the character in AL to the screen
    pop     %ax
    inc     %bx                       # Increment BX, next byte
    
cons_write_sector_ascii_rept:
    dec     %dx                       # Decrement count
    cmpw    $0, %dx         
    jnz     sector_display_ascii
    ret

sector_display_ascii:                 # Display ascii sector portion
    movb    (%bx), %al                # Moving from memory to register at position incremented to by bx
    call    cons_write_sector_ascii   # Display ascii
    ret

### -------------------- ###

real_start:
    movb    %dl, (boot_device) # Boot device number is passed in DL from BIOS. Save it hear since DL might get trashed

    movw    $boot_message, %si  # Display our boot message
    call    cons_writeline

    movw    $booted_from_msg, %si
    call    cons_write

    movb    (boot_device), %dl
    cmp     $0x80, %dl
    jge     harddrive

    movw    $fd, %si
    jmp     finish

sector_start:
    xor     %ax, %ax
    xor     %bx, %bx
    call    sector_user_input                # Asks for user input for sector number
    push    %ax
    call    sector_amount_user_input         # Asks for user input for amount of sectors
    pop     %ax

    call    sector_amount_loop_start         # Loop by sectors
    
    ret

### --------------------------- ###
### Deal with amount of sectors ###

sector_amount_loop_start:
    movw    $1, %cx
    movw    $0, (sector_amount_offset)

sector_amount_loop:
    push    %dx                                 # Preserve registers dx, ax and cx
    push    %ax
    push    %cx

    cmp     $9999, %ax                          # If above 9999 sectors
    ja      sector_above_9999

    cmpw    $0, %dx                             # If user enters 0 sector amount
    je      sector_amount_invalid

    call    sector_load                         # Gets sector number from user input
    movw    (sector_amount_offset), %dx         # DX used for counting rows for offset, start at 0 and count up
    call    sector_load_data                    # Loads sector user entered in sector_user_input and loaded from sector_load
    movw    %dx, (sector_amount_offset)

    pop     %cx                                 # Unpreserv registers cx, ax and dx
    pop     %ax
    pop     %dx

    cmpw    %dx, %cx                            # If sector amount chosen, is the same as count then all sectors displayed
    je      sector_amount_loop_ret

    inc     %ax
    inc     %cx

    jmp     sector_amount_loop

sector_above_9999:                          # If sector goes beyond 9999
    call    cons_write_crlf
    movw    $sector_above_9999_msg, %si     # Display sector chosen message
    call    cons_write                      # Display new line
    jmp     sector_amount_loop_ret

sector_amount_invalid:
    movw    $sector_amount_error, %si       # Display sector chosen message
    call    cons_write                      # Display new line

sector_amount_loop_ret:
    call    cons_write_crlf
    call    cons_write_crlf
    jmp     sector_start                    # Jump to sector_start to ask for user inputs again

### ------------------ ###
###    Display rows    ###

sector_load_data:
    movw    $0xD000, %bx                # Move address 0xD000 into BX
    movw    $0, %ax                     # AX will be used as the count for the end of sector, so when value is 1 end of sector7

sector_input_continue:
    inc     %ax                         # AX incremented to count if sector has been displayed fully or not
    push    %ax                         # Push AX to stack to then pop later and use 0 value 
    movw    $16, %cx                    # 16 hexadecimal character line counter

sector_display_rows:
    push    %dx                         # Preserve DX for counting offset
    call    cons_write_crlf             # Display blank line
    pop     %dx
    
    ###   Offset   ###
    push    %dx                         # Preserve DX for counting offset
    call    sector_display_offset       # Offset functionality

    ###   Hex   ###
    push    %bx                         # Preserve BX for displaying 16 bytes
    movw    $16, %dx                    # Enable display of 16 bytes, 16 hexadecimal
    call    sector_display_hex          # Loop through hex rows - Hex functionality
    pop     %bx

    ###   ASCII   ###
    movw    $16, %dx                   # Enable display of 16 ascii characters - 16 bytes
    call    sector_display_ascii       # Ascii functionality
    
    # Decrementing and comparison, check if all rows have been displayed
    pop     %dx                        # Pop DX to Increment for row count
    inc     %dx                        # Increment DX by 1 to count through offset
    dec     %cx                        # Decrement line counter by 1
    cmpw    $0, %cx                    # Check if counter is 0, check if all characters are printed
    jnz     sector_display_rows        # If characters remain, continue printing

    # User input for continuation
    call    cons_write_crlf            # New line displayed
    movw    $continue_sector_msg, %si  # Display sector chosen message
    call    cons_write                 # Display new line
    call    continue_input             # Call continue_input which allows user to input any keyboard character to continue

    # When end of sector has been reached
    pop     %ax                        # Pop value in AX, 0 was stored at sector_load_data, will be used for sector count
    cmpw    $2, %ax                    # Compare the value in %AX with 1, if 1 then no need to further load as no more sector data is available
    je      end_of_sector              # If whole of sector has been fully displayed, then repeat and ask for another sector
    jmp     sector_input_continue      # If sector has not been fully displayed, continue

end_of_sector:
    # End sector
    ret

### ------------------ ###
###     User input     ###

sector_user_input:
    movw    $boot_sect_num, %si                 # Display user input message
    call    cons_write
    
    xor     %dx, %dx                            # Clear register dx and ax
    xor     %ax, %ax                                
    
    push    %cx
    call    sector_input                        # Get User Input for sector

    push    %si

    cmpw    $0, %cx                             # If CX count is 0 then enter key was pressed without entering digits
    je      sector_input_error                  # Display error message

    push    %ax                                 # Push ax to the stack before being outputted
    call    cons_write_crlf                     # Next line
    movw    $boot_sect_read_msg, %si            # Display sector chosen message
    call    cons_write
    pop     %ax                                 # Pop user input (ax) from stack and put back in to ax register
    pop     %si

    call    cons_write_int

    xor     %si, %si
    movw    %bx, %ax

    xor     %bx, %bx

    pop     %cx

    ret

sector_amount_user_input:
    movw    $boot_sect_amount, %si              # Display user input message
    call    cons_write
    
    xor     %dx, %dx                            # Clear register dx and ax
    xor     %ax, %ax                                
    
    push    %cx
    call    sector_input                        # Get User Input for sector

    push    %si

    cmpw    $0, %cx                             # If CX count is 0 then enter key was pressed without entering digits
    je      sector_input_error                  # Display error message

    push    %ax                                 # Push ax to the stack before being outputted
    call    cons_write_crlf                     # Next line
    movw    $boot_sect_amount_msg, %si          # Display sector chosen message
    call    cons_write
    pop     %ax                                 # Pop user input (ax) from stack and put back in to ax register
    pop     %si

    call    cons_write_int

    xor     %si, %si
    movw    %bx, %dx

    pop     %cx

    ret

sector_input:
    movw    $0, %cx                         # Sector digit count
    movw    $0, %dx                         # Zero count

sector_input_rpt:
    movb    $0x00, %ah                      # AH set to 0
    int     $0x16                           # Interrupt for user input

    cmpb    $13, %al                        # Compare 13 with keyboard input, 13 being carriage return
    je      sector_input_ret                # End loop - return - continue to retrieve sectors

    cmpw    $4, %cx                         # Compare CX count with value 4 (4 digits), if equal then return, only 4 digits required
    je      sector_input_ret                # End loop

    call    sector_input_error_checking     # Check user input is valid

    movb    $0x0e, %ah                      # 0x0e is the INT 10h BIOS call to output the value contained in AL to screen
    int     $0x10                           # Output the character in AL to the screen

    imul    $10, %bx                        # Multiplies value currently in bx by 10 - doesn't multiply first number
    sub     $48, %al                        # Subtract 48 to get integer instead of ascii value
    xor     %ah, %ah                        # Clear register
    addb    %al, %bl                        # Add user input in al to bl, results moved to bl
    inc     %cx

    jmp     sector_input_rpt

sector_input_error_checking:
    cmpb    $48, %al                        # Check if value inputted is equal or below 0
    jb      sector_input_error              # Display error message

    cmpb    $57, %al                        # Check if value inputted is equal or above 9 
    ja      sector_input_error              # Display error message
    ret

sector_input_ret:
    ret

sector_input_error:
    call    cons_write_crlf
    movw    $sector_error, %si              # Display error message
    call    cons_writeline
    xor     %ax, %ax                        # Clear registers AX,BX,DX and CX for sector_start
    xor     %bx, %bx
    xor     %dx, %dx
    xor     %cx, %cx
    jmp     sector_start                    # Jump back to start

continue_input:
    movb    $0x00, %ah 
    int     $0x16
    ret

starting_sector_input:
    movb    $0x00, %ah                      # AH set to 0
    int     $0x16                           # Interrupt for user input

    movb    $0x0e, %ah                      # 0x0e is the INT 10h BIOS call to output the value contained in AL to screen
    int     $0x10                           # Output the character in AL to the screen

    movb    %al, %bl
    ret

### ------------------ ###

sector_load:
    cli                               # BIOS enabled interrupts; disable
    xorw    %si, %si                  # Set %si to zero
    movw    %si, %es                  # -> Extra segment
    movw    %si, %ss                  # -> Stack segment
    
    movw    $disk_address_packet, %si # Move address of the disk address packet into SI 
    movw    $1, 2(%si)               # Set the number of blocks to read to be 1, 1 sector

    movw    $0xD000, 4(%si)           # Set the address to read into (0xD000 in this case)
    movw    %ax, 8(%si)               # Set the first block to read to be block AL (user input) 
    movb    $0x42, %ah                # 0x42 is the int 13h BIOS function to read the disk using LBA addressing
    movb    (boot_device), %dl
    int     $0x13                     # Read the disk
    jc      read_failed	              # The carry flag will be set if an error occured
    movb    (0xD000), %al
    ret

harddrive:
    movw    $hd, %si

finish:
    call    cons_writeline
    call    sector_start

endless_loop:                          # Loop forever more
    jmp     endless_loop    

# Program data

boot_device:
    .byte   0

read_failed:	                      # Display error messages
	movw 	$read_failed_msg, %si
    call    cons_writeline
	
	mov 	$cannot_continue, %si	
    call    cons_writeline

# Format of disk address packet
#
# Offset	Size	Description
#  0          1     size of packet (16 bytes)
#  1          1     always 0
#  2          2     number of sectors to transfer (max 127 on some BIOSes)
#  4          4     transfer buffer (first 2 bytes is 16-bit offset, next 2 bytes is 16 bit segment)
#  8          4     lower 32-bits of 48-bit starting LBA (starting from 0)
#  12         4     upper 16-bits of 48-bit starting LBA (will always be 0 for us)

disk_address_packet:
    .byte   0x10
    .byte   0
    .word   0
    .long   0
    .long   0
    .long   0

sector_amount_offset:
    .long 0

read_failed_msg:
    .string "Unable to read stage 2 of the boot process"
cannot_continue:
    .string "Cannot continue boot process"

test:
    .string "Here"
sector_error:
    .string "Invalid input, must be integer between 0-9..."
sector_amount_error:
     .string "Invalid input, must be integer between 1-9..."
sector_above_9999_msg:
    .string "Sector goes beyond 9999 sectors... "
continue_sector_msg:
    .string "Press a key to continue..."
boot_sect_num:
    .string "Enter the sector number to read: "
boot_sect_amount:
    .string "Enter amount of sectors to display: "
boot_sect_read_msg:
    .string "Displaying contents of sector "
boot_sect_amount_msg:
    .string "Amount of sectors to display "
boot_message:     
    .string "Boot Loader Stage 2 loaded"             
booted_from_msg:
    .string "Booting from "
fd: .string "floppy disk"
hd: .string "hard drive"
