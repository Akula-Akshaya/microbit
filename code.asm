.syntax unified
.global main
.type main, %function

// --- Constants ---
.equ GPIO_PORT0_BASE,      0x50000000
.equ GPIO_PORT1_BASE,      0x50000300
.equ P0_OUT_OFFSET,        0x504
.equ P0_OUTSET_OFFSET,     0x508
.equ P0_OUTCLR_OFFSET,     0x50C
.equ P0_IN_OFFSET,         0x510
.equ P0_DIR_OFFSET,        0x514
.equ P0_DIRSET_OFFSET,     0x518
.equ P0_PINCNF_OFFSET,     0x700

// Micro:bit Pins for Columns
.equ COL1_PIN, 28  // P0.28
.equ COL2_PIN, 11  // P0.11
.equ COL3_PIN, 31  // P0.31
.equ COL4_PIN, 5   // Port 1, pin 5
.equ COL5_PIN, 30  // P0.30

// Micro:bit Pins for Rows
.equ ROW1_PIN, 21  // P0.21
.equ ROW2_PIN, 22  // P0.22
.equ ROW3_PIN, 15  // P0.15
.equ ROW4_PIN, 24  // P0.24
.equ ROW5_PIN, 19  // P0.19

// Button pins
.equ BUTTON_A_PIN, 14  // P0.14
.equ BUTTON_B_PIN, 23  // P0.23

// Random number constants
.equ RANDOM_MAX, 10      
.equ RANDOM_MIN, 1       
.equ DISPLAY_DELAY, 40000 // Delay for display

// Pin configuration values
.equ PIN_CNF_DIR_INPUT,  0
.equ PIN_CNF_DIR_OUTPUT, 1
.equ PIN_CNF_INPUT_CONNECT, 0
.equ PIN_CNF_PULL_DISABLED, 0
.equ PIN_CNF_PULL_PULLUP,   3
.equ PIN_CNF_SENSE_DISABLED, 0

// Stack setup
.section .stack
.align 3
stack_top:
    .space 4096  // Allocate 4KB for stack
stack_bottom:

// Data section
.section .data
.align 2
current_random:    .word 42      // Start with seed value of 42
last_button_state: .word 1       // Last button state (1 = not pressed)
display_buffer:    .space 5*5    // 5x5 LED matrix buffer
digits_buffer:     .space 8      // Buffer for storing digits (max 3 digits + null)

// Font data for 0-9 digits (5x5 pixel format, each digit is represented by 5 bytes)
// The bits are ordered from left to right (LSB is leftmost column)
digit_font:
    // Digit 0
    .byte 0b01110
    .byte 0b10001
    .byte 0b10001
    .byte 0b10001
    .byte 0b01110
    
    // Digit 1
    .byte 0b00100
    .byte 0b01100
    .byte 0b00100
    .byte 0b00100
    .byte 0b01110
    
    // Digit 2
    .byte 0b01110
    .byte 0b10001
    .byte 0b00110
    .byte 0b01000
    .byte 0b11111
    
    // Digit 3
    .byte 0b01110
    .byte 0b10001
    .byte 0b00110
    .byte 0b10001
    .byte 0b01110
    
    // Digit 4
    .byte 0b00110
    .byte 0b01010
    .byte 0b10010
    .byte 0b11111
    .byte 0b00010
    
    // Digit 5
    .byte 0b11111
    .byte 0b10000
    .byte 0b11110
    .byte 0b00001
    .byte 0b11110
    
    // Digit 6
    .byte 0b01110
    .byte 0b10000
    .byte 0b11110
    .byte 0b10001
    .byte 0b01110
    
    // Digit 7
    .byte 0b11111
    .byte 0b00001
    .byte 0b00010
    .byte 0b00100
    .byte 0b01000
    
    // Digit 8
    .byte 0b01110
    .byte 0b10001
    .byte 0b01110
    .byte 0b10001
    .byte 0b01110
    
    // Digit 9
    .byte 0b01110
    .byte 0b10001
    .byte 0b01111
    .byte 0b00001
    .byte 0b01110

// Text section
.section .text

// Vector table
.align 2
vector_table:
    .word stack_top           // Initial SP value
    .word reset_handler       // Reset handler
    .word nmi_handler         // NMI handler
    .word hardfault_handler   // Hard fault handler
    // Add other exception handlers as needed

// Reset handler
reset_handler:
    bl main
    b .  // Infinite loop if main returns

// Default exception handlers
nmi_handler:
hardfault_handler:
    b .  // Infinite loop

main:
    // Save link register
    push {lr}
    
    // Initialize hardware
    bl setup_gpio
    bl clear_display
    
    // Initial random seed
    bl generate_random_number
    
    // Main program loop
main_loop:
    // Check Button A for press - this will generate a new random number if pressed
    bl check_button_a
    
    // Display current random number 
    ldr r0, =current_random
    ldr r1, [r0]
    bl display_number
    
    // Small delay between display refresh cycles
    mov r0, #5000
    bl delay
    
    b main_loop

// Setup GPIO pins
setup_gpio:
    push {r4-r7, lr}
    
    // Configure column pins as outputs (set direction)
    ldr r4, =GPIO_PORT0_BASE
    
    // Column 1 (P0.28)
    mov r0, r4
    mov r1, #COL1_PIN
    bl configure_pin_as_output
    
    // Column 2 (P0.11)
    mov r0, r4
    mov r1, #COL2_PIN
    bl configure_pin_as_output
    
    // Column 3 (P0.31)
    mov r0, r4
    mov r1, #COL3_PIN
    bl configure_pin_as_output
    
    // Column 5 (P0.30)
    mov r0, r4
    mov r1, #COL5_PIN
    bl configure_pin_as_output
    
    // Column 4 (P1.5) - This is on PORT1
    ldr r0, =GPIO_PORT1_BASE
    mov r1, #COL4_PIN
    bl configure_pin_as_output
    
    // Configure row pins as outputs
    ldr r4, =GPIO_PORT0_BASE
    
    // Row 1 (P0.21)
    mov r0, r4
    mov r1, #ROW1_PIN
    bl configure_pin_as_output
    
    // Row 2 (P0.22)
    mov r0, r4
    mov r1, #ROW2_PIN
    bl configure_pin_as_output
    
    // Row 3 (P0.15)
    mov r0, r4
    mov r1, #ROW3_PIN
    bl configure_pin_as_output
    
    // Row 4 (P0.24)
    mov r0, r4
    mov r1, #ROW4_PIN
    bl configure_pin_as_output
    
    // Row 5 (P0.19)
    mov r0, r4
    mov r1, #ROW5_PIN
    bl configure_pin_as_output
    
    // Configure buttons as inputs with pull-up resistors
    // Button A (P0.14)
    mov r0, r4
    mov r1, #BUTTON_A_PIN
    bl configure_pin_as_input_pullup
    
    // Button B (P0.23)
    mov r0, r4
    mov r1, #BUTTON_B_PIN
    bl configure_pin_as_input_pullup
    
    pop {r4-r7, pc}

// Configure a pin as output
// r0 = GPIO port base address
// r1 = Pin number
configure_pin_as_output:
    push {r4-r5, lr}
    
    // Set pin direction to output using DIRSET register
    ldr r4, [r0, #P0_DIRSET_OFFSET]
    mov r5, #1
    lsl r5, r5, r1        // Shift 1 to pin position
    orr r4, r4, r5        // Set bit
    str r4, [r0, #P0_DIRSET_OFFSET]
    
    // Calculate pin configuration register address
    mov r4, #P0_PINCNF_OFFSET
    add r4, r4, r1, lsl #2  // Each pin config is 4 bytes: PINCNF + (pin * 4)
    
    // Configure pin: direction=output, input=disconnected, pull=disabled, sense=disabled
    mov r5, #(PIN_CNF_DIR_OUTPUT | (PIN_CNF_INPUT_CONNECT << 1) | (PIN_CNF_PULL_DISABLED << 2) | (PIN_CNF_SENSE_DISABLED << 16))
    str r5, [r0, r4]
    
    pop {r4-r5, pc}

// Configure a pin as input with pull-up resistor
// r0 = GPIO port base address
// r1 = Pin number
configure_pin_as_input_pullup:
    push {r4-r5, lr}
    
    // Calculate pin configuration register address
    mov r4, #P0_PINCNF_OFFSET
    add r4, r4, r1, lsl #2  // Each pin config is 4 bytes
    
    // Configure pin: direction=input, input=connected, pull=pullup, sense=disabled
    mov r5, #(PIN_CNF_DIR_INPUT | (PIN_CNF_INPUT_CONNECT << 1) | (PIN_CNF_PULL_PULLUP << 2) | (PIN_CNF_SENSE_DISABLED << 16))
    str r5, [r0, r4]
    
    pop {r4-r5, pc}

// Clear the display (turn off all LEDs)
clear_display:
    push {r4-r5, lr}
    
    // Set all column pins high (LEDs off)
    ldr r4, =GPIO_PORT0_BASE
    
    // Column 1 (P0.28)
    mov r5, #1
    lsl r5, r5, #COL1_PIN
    str r5, [r4, #P0_OUTSET_OFFSET]
    
    // Column 2 (P0.11)
    mov r5, #1
    lsl r5, r5, #COL2_PIN
    str r5, [r4, #P0_OUTSET_OFFSET]
    
    // Column 3 (P0.31)
    mov r5, #1
    lsl r5, r5, #COL3_PIN
    str r5, [r4, #P0_OUTSET_OFFSET]
    
    // Column 5 (P0.30)
    mov r5, #1
    lsl r5, r5, #COL5_PIN
    str r5, [r4, #P0_OUTSET_OFFSET]
    
    // Column 4 (P1.5) - This is on PORT1
    ldr r4, =GPIO_PORT1_BASE
    mov r5, #1
    lsl r5, r5, #COL4_PIN
    str r5, [r4, #P0_OUTSET_OFFSET]
    
    // Set all row pins low
    ldr r4, =GPIO_PORT0_BASE
    
    // Row 1 (P0.21)
    mov r5, #1
    lsl r5, r5, #ROW1_PIN
    str r5, [r4, #P0_OUTCLR_OFFSET]
    
    // Row 2 (P0.22)
    mov r5, #1
    lsl r5, r5, #ROW2_PIN
    str r5, [r4, #P0_OUTCLR_OFFSET]
    
    // Row 3 (P0.15)
    mov r5, #1
    lsl r5, r5, #ROW3_PIN
    str r5, [r4, #P0_OUTCLR_OFFSET]
    
    // Row 4 (P0.24)
    mov r5, #1
    lsl r5, r5, #ROW4_PIN
    str r5, [r4, #P0_OUTCLR_OFFSET]
    
    // Row 5 (P0.19)
    mov r5, #1
    lsl r5, r5, #ROW5_PIN
    str r5, [r4, #P0_OUTCLR_OFFSET]
    
    // Clear display buffer
    ldr r4, =display_buffer
    mov r5, #0
    mov r0, #25  // 5x5 = 25 LEDs
clear_buffer_loop:
    strb r5, [r4], #1
    subs r0, r0, #1
    bne clear_buffer_loop
    
    pop {r4-r5, pc}

// Check button A state with edge detection
check_button_a:
    push {r4-r7, lr}
    
    // Read Button A current state
    ldr r4, =GPIO_PORT0_BASE
    ldr r5, [r4, #P0_IN_OFFSET]
    mov r6, #1
    lsl r6, r6, #BUTTON_A_PIN
    tst r5, r6
    
    // r7 will be 0 if button is pressed, 1 if not pressed
    moveq r7, #0
    movne r7, #1
    
    // Load previous button state
    ldr r4, =last_button_state
    ldr r5, [r4]
    
    // Compare with previous state to detect button press edge
    cmp r5, #1          // Was button released before?
    bne check_button_a_exit_update  // If not, skip (avoid repeated triggers)
    
    cmp r7, #0          // Is button pressed now?
    bne check_button_a_exit_update  // If not, skip
    
    // Button was released and is now pressed - generate new random number
    bl generate_random_number
    
    // Clear display after generating a new number
    bl clear_display
    
    // Debounce delay
    mov r0, #20000
    bl delay
    
check_button_a_exit_update:
    // Update button state
    ldr r4, =last_button_state
    str r7, [r4]
    
    pop {r4-r7, pc}

// Generate a new random number between RANDOM_MIN and RANDOM_MAX
// Improved random number generator using a simpler algorithm
generate_random_number:
    push {r4-r7, lr}
    
    // Load current seed
    ldr r4, =current_random
    ldr r5, [r4]
    
    // Use a simpler random algorithm: X_next = (a*X + c) mod m
    // Using smaller values for better stability: a=1103, c=12345
    mov r6, #1103
    mul r5, r5, r6
    
    add r5, r5, #12345
    
    // Store the new seed
    str r5, [r4]
    
    // Scale to range [RANDOM_MIN, RANDOM_MAX]
    // Take only lower 16 bits (mod 2^16)
    and r5, r5, #0xFFFF
    
    // Perform simple scaling: (rand % range) + min
    mov r6, #RANDOM_MAX
    sub r6, r6, #RANDOM_MIN
    add r6, r6, #1        // r6 = range size
    
    // Perform modulo (r5 % r6)
    udiv r7, r5, r6       // r7 = r5 / r6
    mul r7, r7, r6        // r7 = (r5 / r6) * r6
    sub r5, r5, r7        // r5 = r5 - ((r5 / r6) * r6) = r5 % r6
    
    // Add RANDOM_MIN to get the final range
    add r5, r5, #RANDOM_MIN
    
    // Ensure the result is within range (defensive check)
    cmp r5, #RANDOM_MIN
    bge check_max
    mov r5, #RANDOM_MIN
    b store_result
    
check_max:
    cmp r5, #RANDOM_MAX
    ble store_result
    mov r5, #RANDOM_MAX
    
store_result:
    // Store the result
    str r5, [r4]
    
    pop {r4-r7, pc}

// Display a specific LED
// r0 = row (0-4)
// r1 = column (0-4)
// NOTE: For micro:bit LED matrix, we need to set ROW pins HIGH and COLUMN pins LOW to light an LED
display_led:
    push {r4-r7, lr}
    
    // Port 0 base address
    ldr r4, =GPIO_PORT0_BASE
    
    // First, set all ROW pins LOW (turn off)
    // Row 1 (P0.21)
    mov r5, #1
    lsl r5, r5, #ROW1_PIN
    str r5, [r4, #P0_OUTCLR_OFFSET]
    
    // Row 2 (P0.22)
    mov r5, #1
    lsl r5, r5, #ROW2_PIN
    str r5, [r4, #P0_OUTCLR_OFFSET]
    
    // Row 3 (P0.15)
    mov r5, #1
    lsl r5, r5, #ROW3_PIN
    str r5, [r4, #P0_OUTCLR_OFFSET]
    
    // Row 4 (P0.24)
    mov r5, #1
    lsl r5, r5, #ROW4_PIN
    str r5, [r4, #P0_OUTCLR_OFFSET]
    
    // Row 5 (P0.19)
    mov r5, #1
    lsl r5, r5, #ROW5_PIN
    str r5, [r4, #P0_OUTCLR_OFFSET]
    
    // Set all COLUMN pins HIGH (turn off)
    // Column 1 (P0.28)
    mov r5, #1
    lsl r5, r5, #COL1_PIN
    str r5, [r4, #P0_OUTSET_OFFSET]
    
    // Column 2 (P0.11)
    mov r5, #1
    lsl r5, r5, #COL2_PIN
    str r5, [r4, #P0_OUTSET_OFFSET]
    
    // Column 3 (P0.31)
    mov r5, #1
    lsl r5, r5, #COL3_PIN
    str r5, [r4, #P0_OUTSET_OFFSET]
    
    // Column 5 (P0.30)
    mov r5, #1
    lsl r5, r5, #COL5_PIN
    str r5, [r4, #P0_OUTSET_OFFSET]
    
    // Column 4 (P1.5) - This is on PORT1
    ldr r6, =GPIO_PORT1_BASE
    mov r5, #1
    lsl r5, r5, #COL4_PIN
    str r5, [r6, #P0_OUTSET_OFFSET]
    
    // Now set the specific row pin HIGH
    cmp r0, #0
    beq set_row1
    cmp r0, #1
    beq set_row2
    cmp r0, #2
    beq set_row3
    cmp r0, #3
    beq set_row4
    cmp r0, #4
    beq set_row5
    b display_led_done  // Invalid row
    
set_row1:
    mov r5, #1
    lsl r5, r5, #ROW1_PIN
    str r5, [r4, #P0_OUTSET_OFFSET]
    b set_column
    
set_row2:
    mov r5, #1
    lsl r5, r5, #ROW2_PIN
    str r5, [r4, #P0_OUTSET_OFFSET]
    b set_column
    
set_row3:
    mov r5, #1
    lsl r5, r5, #ROW3_PIN
    str r5, [r4, #P0_OUTSET_OFFSET]
    b set_column
    
set_row4:
    mov r5, #1
    lsl r5, r5, #ROW4_PIN
    str r5, [r4, #P0_OUTSET_OFFSET]
    b set_column
    
set_row5:
    mov r5, #1
    lsl r5, r5, #ROW5_PIN
    str r5, [r4, #P0_OUTSET_OFFSET]
    
set_column:
    // Set the specific column pin LOW to light the LED
    cmp r1, #0
    beq set_col1
    cmp r1, #1
    beq set_col2
    cmp r1, #2
    beq set_col3
    cmp r1, #3
    beq set_col4
    cmp r1, #4
    beq set_col5
    b display_led_done  // Invalid column
    
set_col1:
    mov r5, #1
    lsl r5, r5, #COL1_PIN
    str r5, [r4, #P0_OUTCLR_OFFSET]
    b display_led_done
    
set_col2:
    mov r5, #1
    lsl r5, r5, #COL2_PIN
    str r5, [r4, #P0_OUTCLR_OFFSET]
    b display_led_done
    
set_col3:
    mov r5, #1
    lsl r5, r5, #COL3_PIN
    str r5, [r4, #P0_OUTCLR_OFFSET]
    b display_led_done
    
set_col4:
    // Column 4 is on Port 1
    ldr r4, =GPIO_PORT1_BASE
    mov r5, #1
    lsl r5, r5, #COL4_PIN
    str r5, [r4, #P0_OUTCLR_OFFSET]
    b display_led_done
    
set_col5:
    ldr r4, =GPIO_PORT0_BASE
    mov r5, #1
    lsl r5, r5, #COL5_PIN
    str r5, [r4, #P0_OUTCLR_OFFSET]
    
display_led_done:
    pop {r4-r7, pc}

// Delay function
// r0 = delay count
delay:
    push {r4, lr}
    mov r4, r0
delay_loop:
    subs r4, r4, #1
    bne delay_loop
    pop {r4, pc}

// Display a number on the LED matrix by scrolling each digit
// r1 = number to display (1-10)
display_number:
    push {r4-r12, lr}
    
    // Convert number to digits
    mov r4, r1            // r4 = number to display
    ldr r5, =digits_buffer
    mov r6, #0            // r6 = digit counter
    
    // Handle special case for 0
    cmp r4, #0
    bne extract_digits
    
    // Just display a single '0'
    mov r7, #0
    strb r7, [r5, r6]
    add r6, r6, #1
    b display_digits_loop_end
    
extract_digits:
    // Extract digits from right to left
extract_digits_loop:
    cmp r4, #0
    beq extract_digits_loop_end
    
    // Get last digit (number % 10)
    mov r0, r4
    mov r1, #10
    bl divide          // r0 = quotient, r1 = remainder
    
    // Store digit (remainder)
    strb r1, [r5, r6]
    add r6, r6, #1
    
    // Update number (number / 10)
    mov r4, r0
    
    b extract_digits_loop
extract_digits_loop_end:
    
    // Now r6 contains the number of digits
    // Reverse the digits (they're currently stored in reverse)
    mov r7, #0            // r7 = left index
    sub r8, r6, #1        // r8 = right index
    
reverse_digits_loop:
    cmp r7, r8
    bge reverse_digits_loop_end
    
    // Swap digits[left] with digits[right]
    ldrb r9, [r5, r7]     // r9 = digits[left]
    ldrb r10, [r5, r8]    // r10 = digits[right]
    strb r10, [r5, r7]    // digits[left] = r10
    strb r9, [r5, r8]     // digits[right] = r9
    
    add r7, r7, #1        // left++
    sub r8, r8, #1        // right--
    
    b reverse_digits_loop
reverse_digits_loop_end:
    
display_digits_loop_end:
    // Null-terminate the digits buffer
    mov r7, #0xFF
    strb r7, [r5, r6]
    
    // Now display the digits one by one
    ldr r7, =digits_buffer
    
display_digits_loop:
    // Load the current digit
    ldrb r8, [r7], #1
    
    // Check for end of digits
    cmp r8, #0xFF
    beq display_number_done
    
    // Display the digit
    mov r0, r8
    bl display_digit
    
    // Delay between digits
    mov r0, #DISPLAY_DELAY
    bl delay
    
    b display_digits_loop
    
display_number_done:
    pop {r4-r12, pc}

// Divide function: r0 = dividend, r1 = divisor
// Returns: r0 = quotient, r1 = remainder
divide:
    push {r4, lr}
    
    mov r4, r0            // r4 = dividend
    udiv r0, r4, r1       // r0 = dividend / divisor
    mul r2, r0, r1        // r2 = quotient * divisor
    sub r1, r4, r2        // r1 = dividend - (quotient * divisor) = remainder
    
    pop {r4, pc}

// Display a digit on the LED matrix
// r0 = digit (0-9)
display_digit:
    push {r4-r11, lr}
    
    // Clear display first 
    bl clear_display
    
    // Validate digit is in range 0-9
    cmp r0, #9
    bhi display_digit_done  // Skip if invalid digit
    
    // Calculate the offset in digit_font
    // Each digit takes 5 bytes in the font
    ldr r4, =digit_font
    mov r5, #5
    mul r6, r0, r5        // r6 = digit * 5
    add r4, r4, r6        // r4 points to the font data for this digit
    
    // Number of refreshes for the digit
    mov r11, #80          // Increased refresh cycles for visibility
    
digit_refresh_loop:
    // Loop through the rows of the digit
    mov r7, #0            // r7 = current row
display_digit_row_loop:
    // Load the row pattern
    ldrb r8, [r4, r7]     // r8 = pattern for this row
    
    // Loop through columns (bits in the pattern)
    mov r9, #0            // r9 = current column
display_digit_col_loop:
    // Check if the bit is set (we're checking if bit r9 is set in r8)
    mov r10, #1
    lsl r10, r10, r9      // r10 = 1 << column
    tst r8, r10
    beq skip_pixel        // Skip if bit is not set
    
    // Display the LED
    mov r0, r7            // row
    mov r1, r9            // column
    bl display_led
    
    // Small delay to keep the LED visible (increased for better visibility)
    mov r0, #100          // Increased delay for better visibility
    bl delay
    
skip_pixel:
    // Move to next column
    add r9, r9, #1
    cmp r9, #5
    blt display_digit_col_loop
    
    // Move to next row
    add r7, r7, #1
    cmp r7, #5
    blt display_digit_row_loop
    
    // Decrement refresh counter
    subs r11, r11, #1
    bne digit_refresh_loop
    
display_digit_done:
    pop {r4-r11, pc}