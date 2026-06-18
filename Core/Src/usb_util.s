/**
  ******************************************************************************
  * @file      usb_util.s  [15/6/2026]
  * @author    Renan A. Pacheco
  * @brief   Utility functions
  *
  ******************************************************************************
  * @attention
  *
  ******************************************************************************
  */

.syntax unified
.cpu cortex-m0plus
.fpu softvfp
.thumb

.include "usb_def_config.inc"

.global fDelay_5clk
.global fDelay
.global fUsb_initPort_Pins
.global fUsb_setMode_Input
.global fUsb_setMode_Output

/**
 * @brief  busy delay ((R0 * 3) + 1) + (3 for the call [bl]) cycles
 *
 * @param  r0: loops number
 *
 */
.thumb_func
fDelay:             @ ([r0]*3) + 1
    subs   r0, #1           @1,   0/--| dec delay counter
    bne   fDelay            @1/2, 1/3| loop until delay is over
    bx     lr               @2,   2/--| return from delay function


/**
 * @brief  busy delay of 5 cycles with the call (bl)
 */
.thumb_func
fDelay_5clk:  @2
    bx lr


/**
 * @brief  Set USB pins as INPUTs
 * @note  Uses registers R3, R4, R7
 */
.thumb_func
fUsb_setMode_Input:
    push    {r5-r7}
    ldr     r7, =USB_GPIO_MODER
    ldr     r5, [r7]                         @ load current value of MODER
    ldr     r6, =USB_GPIO_MODE_SPEED_MASK    @ mask bits
    ands    r6, r5                           @ clear bits
    ldr     r5, =USB_GPIO_INPUT
    orrs    r6, r5                           @ set bits for input
    str     r6, [r7]                         @ update value of MODER
    pop     {r5-r7}
    bx    lr


/**
 * @brief  Initialize USB Port pins
 *
 */
.thumb_func
fUsb_initPort_Pins:
    push    {r5-r7}
    ldr     r7, =USB_GPIO_OSPEEDR
    ldr     r6, [r7]                         @ load current value of OSPEEDR
    ldr     r5, =USB_GPIO_MODE_SPEED_MASK    @ mask bits
    ands    r5, r6                           @ clear bits to update
    ldr     r6, =USB_GPIO_HIGHSPEED
    orrs    r5, r6                           @ set bits for high speed
    str     r5, [r7]                         @ update value to OSPEEDR
    pop     {r5-r7}
    bx    lr


.thumb_func
fUsb_setMode_Output:
    push    {r5-r7}
    ldr     r7, =USB_GPIO_BSRR
    ldr     r5, =USB_DIFF_0
    str     r5, [r7]                         @ set D+ low, D- high (idle state)
    ldr     r7, =USB_GPIO_MODER
    ldr     r5, [r7]                         @ load current value of MODER
    ldr     r6, =USB_GPIO_MODE_SPEED_MASK    @ mask bits
    ands    r6, r5                           @ clear bits
    ldr     r5, =USB_GPIO_OUTPUT
    orrs    r6, r5                           @ set bits for output
    str     r6, [r7]                         @ update value of MODER
    pop     {r5-r7}
    bx    lr
