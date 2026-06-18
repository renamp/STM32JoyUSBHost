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
.global USB_SendBytes
.global USB_SendTokenPacket

.include "usb_def_config.inc"


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
.thumb_func
Send_RawDiff:
    push {r4-r7, lr}        @ save registers
    bl   fUsb_setMode_Output
    ldr    r7, =USB_GPIO_BSRR
    ldr    r5, =USB_DIFF_0
    ldr    r6, =USB_DIFF_1
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
    bl    Sd_RD_fSIGNAL     @2[3:4], -/--| send bit to USB lines
    lsrs    r2, #1          @1,      4/--| shift byte to get next bit in carry
    subs    r0, #1          @1,      5/--| dec bit length
    beq   Send_RawDiff_End  @1/2,    6/7| branch if more bits to send
    ldrb    r3, [r1]        @2,      7/--| dummy
    ldrb    r3, [r1]        @2,      9/--| dummy

    bl    Sd_RD_fSIGNAL     @2[3:4], -/--| send bit to USB lines
    lsrs    r2, #1          @1,      4/--| shift byte to get next bit in carry
    subs    r0, #1          @1,      5/--| dec bit length
    beq   Send_RawDiff_End  @1/2,    6/7| branch if more bits to send -- [8/9]
    ldrb    r3, [r1]        @2,      7/--| dummy
    ldrb    r3, [r1]        @2,      9/--| dummy

    bl    Sd_RD_fSIGNAL     @2[3:4], -/--| send bit to USB lines
    lsrs    r2, #1          @1,      4/--| shift byte to get next bit in carry
    subs    r0, #1          @1,      5/--| dec bit length
    beq   Send_RawDiff_End  @1/2,    6/7| branch if more bits to send -- [8/9]
    ldrb    r3, [r1]        @2,      7/--| dummy
    ldrb    r3, [r1]        @2,      9/--| dummy

    bl    Sd_RD_fSIGNAL     @2[3:4], -/--| send bit to USB lines
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
    ldr     r1, =USB_DIFF_0 @2,   2/--
    movs    r0, #2          @2,   4/--| load delay
    bl    Sd_RD_fDelay      @2(r0*3+1),  9/15| delay to ensure SE0 is detected
    str     r1, [r2]        @2,  set D+ low, D- high (idle state)

    ldr    r0, =0x00
    ldr    r1, =0x00
    pop   {pc}
