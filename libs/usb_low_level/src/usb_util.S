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

#include "usb_conf.h"

#if defined(__ARM_ARCH_7M__)
  .cpu cortex-m3
#elif defined(__ARM_ARCH_6M__)
  .cpu cortex-m0plus
#endif

.syntax unified
.fpu softvfp
.thumb

.include "usb_def_config.inc"

.global fDelay_5clk
.global _fDelay
.global _fDelay_r4
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
.align
_fDelay:             @ ([r0]*3) + 1
    subs   r0, #1           @1,   0/--| dec delay counter
    bne   _fDelay            @1/2, 1/3| loop until delay is over
    bx     lr               @2,   2/--| return from delay function

.thumb_func
.align 3
_fDelay_r4:           @ (1+([r4]*3))  Same function but using R4
    subs   r4, #1           @1,   0/--| dec delay counter
    bne   _fDelay_r4         @1/2, 1/3| loop until delay is over
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
#if defined(STM32G030xx)
    ldr     r7, =USB_GPIO_MODER
    ldr     r5, [r7]                         @ load current value of MODER
    ldr     r6, =USB_GPIO_MODE_SPEED_MASK    @ mask bits
    ands    r6, r5                           @ clear bits
    ldr     r5, =USB_GPIO_INPUT
    orrs    r6, r5                           @ set bits for input
    str     r6, [r7]                         @ update value of MODER
#elif defined(STM32F103xB)
    ldr     r7, =USB_GPIO_CRL
    ldr     r5, [r7]                         @ load current value of CRL
    ldr     r6, =USB_GPIO_CRL_MSK            @ load mask bits
    ands    r6, r5                           @ apply mask bits
    ldr     r5, =USB_GPIO_CRL_IN             @ load input config
    orrs    r6, r5                           @ appy input config
    str     r6, [r7]                         @ update value of CRL
    ldr     r7, =USB_GPIO_CRH
    ldr     r5, [r7]                         @ load current value of CRH
    ldr     r6, =USB_GPIO_CRH_MSK            @ load mask bits
    ands    r6, r5                           @ apply mask bits
    ldr     r5, =USB_GPIO_CRH_IN             @ load input config
    orrs    r6, r5                           @ appy input config
    str     r6, [r7]                         @ update value of CRH
#endif
    pop     {r5-r7}
    bx    lr


.thumb_func
fUsb_setMode_Output:
    push    {r5-r7}
    ldr     r7, =USB_GPIO_BSRR
    ldr     r5, =USB_DIFF_0
    str     r5, [r7]                         @ set D+ low, D- high (idle state)
#if defined(STM32G030xx)
    ldr     r7, =USB_GPIO_MODER
    ldr     r5, [r7]                         @ load current value of MODER
    ldr     r6, =USB_GPIO_MODE_SPEED_MASK    @ mask bits
    ands    r6, r5                           @ clear bits
    ldr     r5, =USB_GPIO_OUTPUT
    orrs    r6, r5                           @ set bits for output
    str     r6, [r7]                         @ update value of MODER
    ldr     r7, =USB_GPIO_OSPEEDR
    ldr     r6, [r7]                         @ load current value of OSPEEDR
    ldr     r5, =USB_GPIO_MODE_SPEED_MASK    @ mask bits
    ands    r5, r6                           @ clear bits to update
    ldr     r6, =USB_GPIO_HIGHSPEED
    orrs    r5, r6                           @ set bits for high speed
    str     r5, [r7]                         @ update value to OSPEEDR
#elif defined(STM32F103xB)
    ldr     r7, =USB_GPIO_CRL
    ldr     r5, [r7]                         @ load current value of CRL
    ldr     r6, =USB_GPIO_CRL_MSK            @ load mask bits
    ands    r6, r5                           @ apply mask bits
    ldr     r5, =USB_GPIO_CRL_OUT            @ load output config
    orrs    r6, r5                           @ appy output config
    str     r6, [r7]                         @ update value of CRL
    ldr     r7, =USB_GPIO_CRH
    ldr     r5, [r7]                         @ load current value of CRH
    ldr     r6, =USB_GPIO_CRH_MSK            @ load mask bits
    ands    r6, r5                           @ apply mask bits
    ldr     r5, =USB_GPIO_CRH_OUT            @ load output config
    orrs    r6, r5                           @ appy output config
    str     r6, [r7]                         @ update value of CRH
#endif
    pop     {r5-r7}
    bx    lr


.global fUsb_setMode_Reset
.thumb_func
fUsb_setMode_Reset:
    push  {lr}
    bl fUsb_setMode_Output
    ldr     r1, =USB_GPIO_BSRR
    ldr     r0, =USB_SE0
    str     r0, [r1]

#if defined(STM32F103xB)
// Enable Core Debug Trace (Set bit 24 in DEMCR)
    ldr     r0, =DEMCR          @ Load DEMCR address
    ldr     r1, [r0]            @ Read current value
    orr     r1, #0x01000000     @ Set TRCENA bit (bit 24)
    str     r1, [r0]            @ Write back to DEMCR
    ldr     r0, =DWT_CTRL       @ Load DWT_CTRL address
    ldr     r1, [r0]            @ Read current value
    orr     r1, #1              @ Set CYCCNTENA bit (bit 0)
    str     r1, [r0]            @ Write back to DWT_CTRL
  #if defined(USB_DEBUG_PIN)
    bl fUsb_DBGsetMode_Output
  #endif
#endif
    pop   {pc}


.thumb_func
fUsb_DBGsetMode_Output:
#if defined(STM32F103xB)
  #if defined(USB_DEBUG_PIN)
    #if (USB_DEBUG_PIN >= 0) && (USB_DEBUG_PIN <= 7)
      #define _USB_DBG_P_CR USB_DEBUG_PIN
      ldr     r0, =USB_GPIO_CRL
    #elif (USB_DEBUG_PIN >= 8) && (USB_DEBUG_PIN <= 15)
      #define _USB_DBG_P_CR (USB_DEBUG_PIN - 8)
      ldr     r0, =USB_GPIO_CRH
    #endif
    ldr     r1, [r0]                         @ load current value of CR[L/H]
    ldr     r2, =~(0b1111 << (4 * _USB_DBG_P_CR))   @ mask bits
    ands    r1, r2                           @ clear bits
    ldr     r2, =(0b0011 << (4 * _USB_DBG_P_CR))    @ Output high speed
    orrs    r1, r2                           @ set bits for output
    str     r1, [r0]                         @ update value value of CR[L/H]
    ldr     r0, =USB_GPIO_BSRR
    ldr     r1, =(1 << (16 + USB_DEBUG_PIN))      @ LOW
    str     r1, [r0]
  #endif
#endif
    bx   lr
