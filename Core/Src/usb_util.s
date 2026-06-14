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
.type fDelay_5clk, %function

.global fDelay
.type fDelay, %function

.global fUsb_set_input_mode
.type fUsb_set_input_mode, %function

/**
 * @brief  busy delay ((R0 * 3) + 1) + (3 for the call [bl]) cycles
 *
 * @param  r0: loops number
 *
 */
fDelay:             @ ([r0]*3) + 1
    subs   r0, #1           @1,   0/--| dec delay counter
    bne   fDelay            @1/2, 1/3| loop until delay is over
    bx     lr               @2,   2/--| return from delay function


/**
 * @brief  busy delay of 5 cycles with the call (bl)
 */
fDelay_5clk:  @2
    bx lr


/**
 * @brief  Set USB pins as INPUTs
 * @note  Uses registers R3, R4, R7
 */
fUsb_set_input_mode:
    ldr    r7, =USB_GPIO_MODER
    ldr    r4, [r7]                     @ load current value of MODER
    ldr    r3, =USB_GPIO_MODE_SPEED_MASK   @ mask bits
    ands   r3, r4                       @ clear bits
    ldr    r4, =USB_GPIO_INPUT
    orrs   r3, r4                       @ set bits for input
    str    r3, [r7]                     @ update value of MODER
    bx lr
