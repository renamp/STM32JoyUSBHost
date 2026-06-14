/**
  ******************************************************************************
  * @file      Usb_data_signaling.s  [10/6/2026]
  * @author    Renan A. Pacheco
  * @brief   Handle USB differential signal transmission timing
  *     This module:
  *         - Module designed for systemCoreFrequency = 24MHz
  *         - Transmit and receive USB differential signal
  *         - Uses PA0 for (D-) and PA1 for (D+)
  *
  ******************************************************************************
  * @attention
  *     This module is strongly dependent of Core running at 24MHz frequency.
  ******************************************************************************
  */

.syntax unified
.cpu cortex-m0plus
.fpu softvfp
.thumb

.global Send_RawDiff
.type Send_RawDiff, %function

.global USB_PortPins_Init
.type USB_PortPins_Init, %function

.equ USB_GPIO_BASE,             0x50000000
.equ USB_GPIO_D_MINUS_PIN,      0x00
.equ USB_GPIO_D_PLUS_PIN,       0x01

.equ USB_GPIO_MODER,      USB_GPIO_BASE + 0x00
.equ USB_GPIO_OTYPER,     USB_GPIO_BASE + 0x04
.equ USB_GPIO_OSPEEDR,    USB_GPIO_BASE + 0x08
.equ USB_GPIO_PUPDR,      USB_GPIO_BASE + 0x0C
.equ USB_GPIO_IDR,        USB_GPIO_BASE + 0x10
.equ USB_GPIO_ODR,        USB_GPIO_BASE + 0x14
.equ USB_GPIO_BSRR,       USB_GPIO_BASE + 0x18
.equ USB_DMP,             USB_GPIO_D_MINUS_PIN
.equ USB_DPP,             USB_GPIO_D_PLUS_PIN
.equ USB_DM_MSM,          (0b11 << (2 * USB_DMP))
.equ USB_DP_MSM,          (0b11 << (2 * USB_DPP))
.equ USB_DM_OM,           (0b01 << (2 * USB_DMP))
.equ USB_DP_OM,           (0b01 << (2 * USB_DPP))
.equ USB_DM_SOH,          (1 << USB_DMP)             // (D-) Set Output HIGH
.equ USB_DM_SOL,          (1 << (USB_DMP + 16))      // (D-) Set Output LOW
.equ USB_DP_SOH,          (1 << USB_DPP)             // (D+) Set Output HIGH
.equ USB_DP_SOL,          (1 << (USB_DPP + 16))      // (D+) Set Output LOW
.equ USB_GPIO_MODE_SPEED_MASK,  ~(USB_DM_MSM | USB_DP_MSM)
.equ USB_GPIO_OUTPUT,     (USB_DM_OM | USB_DP_OM)    // use Output mode
.equ USB_GPIO_HIGHSPEED,  (USB_DM_MSM | USB_DP_MSM)  // use High Speed
.equ USB_DIFFERENTIAL_1,  (USB_DM_SOL | USB_DP_SOH)  // (D+)=1, (D-)=0
.equ USB_DIFFERENTIAL_0,  (USB_DM_SOH | USB_DP_SOL)  // (D+)=0, (D-)=1
.equ USB_SE0,             (USB_DM_SOL | USB_DP_SOL)  // (D+)=0, (D-)=0


/**
 * @brief  Initialize USB Port pins and change OUTPUT and INPUT
 *
 * @param void
 * @retval void
 *
 * @note
 *
 */
USB_PortPins_Init:
    ldr    r7, =USB_GPIO_OSPEEDR
    ldr    r4, [r7]                     @ load current value of OSPEEDR
    ldr    r3, =USB_GPIO_MODE_SPEED_MASK   @ mask bits
    ands   r3, r4                       @ clear bits to update
    ldr    r4, =USB_GPIO_HIGHSPEED
    orrs   r3, r4                       @ set bits for high speed
    str    r3, [r7]                     @ update value to OSPEEDR
    bx lr

USB_Output_mode:
    ldr    r7, =USB_GPIO_BSRR
    ldr    r5, =USB_DIFFERENTIAL_0
    str    r5, [r7]                     @ set D+ low, D- high (idle state)
    ldr    r7, =USB_GPIO_MODER
    ldr    r4, [r7]                     @ load current value of MODER
    ldr    r3, =USB_GPIO_MODE_SPEED_MASK   @ mask bits
    ands   r3, r4                       @ clear bits
    ldr    r4, =USB_GPIO_OUTPUT
    orrs   r3, r4                       @ set bits for output
    str    r3, [r7]                     @ update value of MODER
    bx     lr


/**
 * @brief  Send Raw differential data bits
 *
 * @param  r0: Length of array differential bits
 * @param  r1: Pointer of array differential bits
 * @retval void
 *
 * @note
 *
 */
Send_RawDiff:
    push {r4-r7, lr}        @ save registers
@ set usb lines to output
    ldr    r7, =USB_GPIO_BSRR
    ldr    r5, =USB_DIFFERENTIAL_0
    ldr    r6, =USB_DIFFERENTIAL_1
    bl   USB_Output_mode
    ldr    r7, =USB_GPIO_BSRR
    b    Send_RawDiff_L1    @ jump to send raw diff bits

Sd_RD_fSIGNAL:
    lsrs    r2, #1          @1,   3/--| shift byte to get next bit in carry
    bcs  Sd_RD_fSIGNAL1     @1/2, 4/5| branch if bit is 1
    nop                     @1,   5/--| small delay to ensure signal is stable
    str     r6, [r7]        @2,   0/--| set D+ low, D- high (1)
    bx      lr              @2,   2/--| return from signal function
Sd_RD_fSIGNAL1:
    str     r5, [r7]        @2,   0/--| set D+ high, D- low (0)
    bx      lr              @2,   2/--| return from signal function

Sd_RD_fDelay:  @ (1+([r0]*3))
    subs   r0, #1           @1,   0/--| dec delay counter
    bne   Sd_RD_fDelay      @1/2, 1/3| loop until delay is over
    bx     lr               @2,   2/--| return from delay function

Send_RawDiff_L1:
    ldrb    r2, [r1]        @2,     8/-- | load byte from data in
    subs    r1, #1          @1,    10/-- | dec data pointer
    bl    Sd_RD_fSIGNAL     @3[3:4], -/--| send bit to USB lines
    lsrs    r2, #1          @1,      4/--| shift byte to get next bit in carry
    subs    r0, #1          @1,      5/--| dec bit length
    beq   Send_RawDiff_End  @1/2,    6/7| branch if more bits to send
    ldrb    r3, [r1]        @2,      7/--| dummy
    ldrb    r3, [r1]        @2,      9/--| dummy

    bl    Sd_RD_fSIGNAL     @3[3:4], -/--| send bit to USB lines
    lsrs    r2, #1          @1,      4/--| shift byte to get next bit in carry
    subs    r0, #1          @1,      5/--| dec bit length
    beq   Send_RawDiff_End  @1/2,    6/7| branch if more bits to send -- [8/9]
    ldrb    r3, [r1]        @2,      7/--| dummy
    ldrb    r3, [r1]        @2,      9/--| dummy

    bl    Sd_RD_fSIGNAL     @3[3:4], -/--| send bit to USB lines
    lsrs    r2, #1          @1,      4/--| shift byte to get next bit in carry
    subs    r0, #1          @1,      5/--| dec bit length
    beq   Send_RawDiff_End  @1/2,    6/7| branch if more bits to send -- [8/9]
    ldrb    r3, [r1]        @2,      7/--| dummy
    ldrb    r3, [r1]        @2,      9/--| dummy

    bl    Sd_RD_fSIGNAL     @3[3:4], -/--| send bit to USB lines
    lsrs    r2, #1          @1,      4/--| shift byte to get next bit in carry
    subs    r0, #1          @1,      5/--| dec bit length
    bne   Send_RawDiff_L1   @1/2     6/7
    nop                     @1       7/--
Send_RawDiff_End:
    movs    r2, #0          @2,      9/--| clear
    ldr     r4, =USB_SE0    @2,     11/--| load SE0 for signal end of packet
    ldrb    r3, [r1]        @2,     13/--| dummy
    nop                     @1,     15/--| dummy

    str     r4, [r7]        @2,      0/--| set SE0 to signal end of packet
    pop     {r4-r7}         @1+4,    2/--
    movs    r0, #1          @2,      7/--| load delay
    bl    Sd_RD_fDelay      @2(r0*3+1),  9/15| delay to ensure SE0 is detected

    ldr     r2, =USB_GPIO_BSRR      @2,   0/--
    ldr     r1, =USB_DIFFERENTIAL_0 @2,   2/--
    movs    r0, #2                  @2,   4/--| load delay
    bl    Sd_RD_fDelay      @2(r0*3+1),  9/15| delay to ensure SE0 is detected
    str     r1, [r2]        @2,  set D+ low, D- high (idle state)

    movs r0, #0x00
    movs r1, #0x00
    pop {pc}
