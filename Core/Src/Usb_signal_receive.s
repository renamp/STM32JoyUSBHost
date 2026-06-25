/**
  ******************************************************************************
  * @file      Usb_signal_receive.s  [11/6/2026]
  * @author    Renan A. Pacheco
  * @brief   Handle USB differential signal receive timing
  *     This module:
  *         - Module designed for systemCoreFrequency = 24MHz
  *         - receive USB differential signal
  *         - PORT and PINS for (D-) and (D+) in usb_def_config.inc
  *
  ******************************************************************************
  * @attention
  *     This module is strongly dependent of Core running at 24MHz frequency.
  ******************************************************************************
  */
#

#include "usb_conf.h"

#ifndef __FCPU__
  #error "USB Host: Please Define __FCPU__ in usb_conf.h with core Frequency"
#else
  #if __FCPU__ == 0
    #error "USB Host: Please set __FCPU__ in usb_conf.h with core Frequency"
  #else
    #if defined(__ARM_ARCH_7M__)
      #if (__FCPU__ == 64000000)
        .cpu cortex-m3
      #else
        #error "USB Host: __FCPU__ Frequency not supported. "
      #endif
    #elif defined(__ARM_ARCH_6M__)
      #if (__FCPU__ == 24000000)
        .cpu cortex-m0plus
      #else
        #error "USB Host: __FCPU__ Frequency not supported. "
      #endif
    #endif
  #endif
#endif
#if defined(USB_DEBUG_PIN)
  #pragma message("USB Host: DEBUG_PIN enabled. This assist to analyse\
                    signal timing.")
#endif

.syntax unified
.fpu softvfp
.thumb

.global USB_ReceiveBytes
.global USB_ReceiveBytesAck

.include "usb_def_config.inc"

/**
 * @brief  Receive bytes from device and send ACK packet after
 *
 * @param  r0: ptr_out, pointer where to store data received
 * @retval  length of bytes received
 * @note
 *    prototype:
 *      extern uint8_t USB_ReceiveBytesAck(uint8_t *ptr_out);
 */
.thumb_func
USB_ReceiveBytesAck:
    ldr    r3, =1;	    @ send Ack packet after receive bytes
    b	 Receive_Bytes_INI1

/**
 * @brief  Only Receive bytes from device
 *
 * @param  r0: ptr_out, pointer where to store data received
 * @retval  length of bytes received
 * @note
 *    prototype:
 *      extern uint8_t USB_ReceiveBytes(uint8_t *ptr_out);
 */
.thumb_func
USB_ReceiveBytes:
    ldr    r3, =0
Receive_Bytes_INI1:
    push   {r4-r7, lr}
    mov    r4, r8
    mov    r5, r9
    mov    r6, r10
    mov    r7, r11
    push   {r4-r7}
    CPSID  i			        @ disable interrupt
    push   {r0}			        @ pointer outArray
    mov    r1, sp                   @ [r1] stack index for diff array
    subs   r1, #OFFSET_FROM_STACK   @ leave some space on stack
    push   {r3}			    @ store param: (0) No_ACK / (1) ACK
    bl   fUsb_setMode_Input
    ldr    r2, =USB_DIMSK
    ldr    r3, =USB_DATA_K
    ldr    r4, =USB_DATA_J
    ldr    r5, =USB_SYNC_TIMEOUT
    ldr    r6, =USB_GPIO_IDR
#if defined(__ARM_ARCH_6M__)
    movs   r7, #NUMBER_DIFF_BITS_IN_BYTE
    mov    r11, r7           @  ; [r11] reset value for diff bits counters
#elif defined(__ARM_ARCH_7M__)
    ldr    r9, =DWT_CYCCNT
  #if defined(USB_DEBUG_PIN)
    ldr    r11, =USB_DEBUG_BSRR
    ldr    r0, =(1 << (16 + 2))       @ #DEBUG LOW
  #endif

.align 3
#endif
Rcv_wait_first_bit:
    ldrh   r7, [r6]          @2,   [0:1]    ; Read input (D- and D+)
    ands   r7, r2            @1,   [2]
    cmp    r7, r3            @1,   [3]      ; Check if input changed
    beq  RCV_wait_sec_bit    @1/2, [4:4/5]
    subs   r5, #1            @1,   [5]      ; dec timeout
    beq  Rcv_Bytes_SyncErro  @1/2, [6]
    ldrh   r7, [r6]          @2,   [0:1]    ; Read input (D- and D+)
    ands   r7, r2            @1,   [2]
    cmp    r7, r3            @1,   [3]      ; check if input changed
    bne  Rcv_wait_first_bit  @1/2, [4:4/5]
#if defined(__ARM_ARCH_6M__)
RCV_wait_sec_bit:
    ldr    r7, =1            @2,   [5:6]    ;
    mov    r12, r7           @1,   [7]      ; [r12] always 1 to inc counters
    nop                      @1,   [8]      [ dummy to fill timing]
    bl   fDelay_5clk         @3+2, [9:13]   [ dummy to fill timing]
    bl   fDelay_5clk         @3+2, [14:18]  [ dummy to fill timing]
Rcv_sync_sec_bit:
    ldrh   r7, [r6]          @2,   [0:1]    ; Read input (D- and D+)
    ands   r7, r2            @1,   [2]      ; Apply input mask
    cmp    r7, r4            @1,   [3]      ; Check if input changed
    bne  Rcv_Bytes_SyncErro  @1/2, [4:4/5]
Rcv_wait_third_bit:
    ldrh   r7, [r6]          @2,   [0:1]    ; Read input (D- and D+)
    ands   r7, r3            @1,   [2]      ; Check if input changed
    beq   Rcv_wait_third_bit @1/2, [3:3/4]  ; Loop to waint for sync bit 3
    movs   r5, #4            @1,   [4]      ; Counter for remaining sync bits
    bl   fDelay_5clk         @3+2, [5:9]    [ dummy to fill timing]
    bl   fDelay_5clk         @3+2, [10:14]  [ dummy to fill timing]
    ldr    r0, =0            @2,   [15:16]  [ dummy to fill timing]
    nop                      @1,   [23]     [ dummy to fill timing]
RCV_sync_bits_loop:
    bl   fDelay_5clk         @3+2, [12:16]  [ dummy to fill timing]
    nop                      @1,   [17]     [ dummy to fill timing]
    ldrh   r7, [r6]          @2,   [0:1]    ; Read input (D- and D+)
    ands   r7, r2            @1,   [2]      ; Apply input mask
    cmp    r7, r4            @1,   [3]      ; Check if input changed
    bne  Rcv_Bytes_SyncErro  @1/2, [4:4/5]
    mov    r7, r4            @1,   [5]      ; Swap [r3] and [r4]
    mov    r4, r3            @1,   [6]      ; For next sync bit check
    mov    r3, r7            @1,   [7]
    subs   r5, #1            @1,   [8]      ; dec remaining sync bits counter
    nop                      @1,   [9]     [ dummy to fill timing]
    bne  RCV_sync_bits_loop  @1/2, [10:10/11]
    ldr    r4, =DIFF_IC_MASK @2,   [11:12]  ; Mask for incomming diff bits
    ldr    r7, =0            @2,   [13:14]  [ dummy to fill timing]
RCV_last_sync_bit:
    ldrh   r7, [r6]          @2,   [0:1]    ; Read input (D- and D+)
    tst    r7, r3            @1,   [2]      ; Check if input changed
    beq  Rcv_Bytes_SyncErro  @1/2, [3]
    mov    r2, r3            @1,   [4]      ; [r2] State after sync (Data K)
    ldr    r7, =INI_L_ENC_DIFF @2,   [5:6]    ; Initial value of last enc.diff
    mov    r5, r7            @1,   [7]      ; Last encoded differential pair
    movs   r7, #0            @1,   [8]
    mov    r8, r7            @1,   [9]      ; [r8] Clear diff bits counter
    mov    r0, r7            @1,   [10]     ; [r0] Initial state of diff storage
    ldr    r3, =USB_DIMSK    @2,   [11:12]  ; [r3] Input pins mask
    ldr    r7, =0xFFFF       @2,   [13:14]
    mov    r10, r7           @1,   [15]     ; [r10] const = 0xffff
    nop                      @1,   [16]     [ dummy to fill timing]
RCV_data_bits_loop:
    ldrh   r7, [r6]          @2,   [0:1]    ; Read input (D- and D+)
    ands   r7, r3            @1,   [2]      ; Apply input pins mask
    beq  Rcv_Bytes_EOP       @1/2, [3:3/4]  ; Branch if (D- and D+ == 0)
    add    r8, r12           @1,   [4]      ; inc diff bits counter
    tst    r7, r2            @1,   [5]      ; Check if Data state changed
    bne  Rcv_no_change_1aux  @1/2, [6:6/7]
    mov    r2, r7            @1,   [7]      ; Update last input
    mov    r7, r10           @1,   [8]      ; Load 0xffff
    eors   r5, r7            @1,   [9]      ; Invert last enc.diff
Rcv_no_change_1:
    ands   r5, r4            @1,   [10]     ; Mask new enc.diff
    lsrs   r0, #2            @1,   [11]     ; Shift to position
    orrs   r0, r5            @1,   [12]     ; Update enc.diff storage
    nop                      @1,   [13]     [ dummy to fill timing]
    b    Rcv_diff_bit_2      @2,   [14:15]  ;
Rcv_no_change_1aux:
    b    Rcv_no_change_1     @2,   [8:9]    ; Trick to fill timing

Rcv_diff_bit_2:
    ldrh   r7, [r6]          @2,   [0:1]    ; Read input (D- and D+)
    ands   r7, r3            @1,   [2]      ; Apply input pins mask
    beq  Rcv_Bytes_EOP       @1/2, [3:3/4]  ; Branch if (D- and D+ == 0)
    add    r8, r12           @1,   [4]      ; inc diff bits counter
    tst    r7, r2            @1,   [5]      ; Check if Data state changed
    bne  Rcv_no_change_2aux  @1/2, [6:6/7]
    mov    r2, r7            @1,   [7]      ; Update last input
    mov    r7, r10           @1,   [8]      ; Load 0xffff
    eors   r5, r7            @1,   [9]      ; Invert last enc.diff
Rcv_no_change_2:
    ands   r5, r4            @1,   [10]     ; Mask new enc.diff
    lsrs   r0, #2            @1,   [11]     ; Shift to position
    orrs   r0, r5            @1,   [12]     ; Update enc.diff storage
    nop                      @1,   [13]     [ dummy to fill timing]
    nop                      @1,   [14]     [ dummy to fill timing]
    b    Rcv_diff_bit_3      @2,   [15:16]  ;
Rcv_no_change_2aux:
    b    Rcv_no_change_2     @2,   [8:9]    ; Trick to fill timing

Rcv_diff_bit_3:
    ldrh   r7, [r6]          @2,   [0:1]    ; Read input (D- and D+)
    ands   r7, r3            @1,   [2]      ; Apply input pins mask
    beq  Rcv_Bytes_EOP       @1/2, [3:3/4]  ; Branch if (D- and D+ == 0)
    add    r8, r12           @1,   [4]      ; inc diff bits counter
    tst    r7, r2            @1,   [5]      ; Check if Data state changed
    bne  Rcv_no_change_3aux  @1/2, [6:6/7]
    mov    r2, r7            @1,   [7]      ; Update last input
    mov    r7, r10           @1,   [8]      ; Load 0xff
    eors   r5, r7            @1,   [9]      ; Invert last enc.diff
Rcv_no_change_3:
    ands   r5, r4            @1,   [10]     ; Mask new enc.diff
    lsrs   r0, #2            @1,   [11]     ; Shift to position
    orrs   r0, r5            @1,   [12]     ; Update enc.diff storage
    nop                      @1,   [13]     [ dummy to fill timing]
    nop                      @1,   [14]     [ dummy to fill timing]
    b    Rcv_diff_bit_4      @2,   [15:16]  ;
Rcv_no_change_3aux:
    b    Rcv_no_change_3     @2,   [8:9]    ; Trick to fill timing

Rcv_diff_bit_4:
    ldrh   r7, [r6]          @2,   [0:1]    ; Read input (D- and D+)
    ands   r7, r3            @1,   [2]      ; Apply input pins mask
    beq  Rcv_Bytes_EOP       @1/2, [3:3/4]  ; Branch if (D- and D+ == 0)
    add    r8, r12           @1,   [4]      ; inc diff bits counter
    tst    r7, r2            @1,   [5]      ; Check if Data state changed
    bne  Rcv_no_change_4aux  @1/2, [6:6/7]
    mov    r2, r7            @1,   [7]      ; Update last input
    mov    r7, r10           @1,   [8]      ; Load 0xff
    eors   r5, r7            @1,   [9]      ; Invert last enc.diff
Rcv_no_change_4:
    ands   r5, r4            @1,   [10]     ; Mask new enc.diff
    lsrs   r0, #2            @1,   [11]     ; Shift to position
    orrs   r0, r5            @1,   [12]     ; Update enc.diff storage
    strb   r0, [r1]          @2,   [13:14]
    subs   r1, #1            @1,   [15]     ; dec pointer
    b    RCV_data_bits_loop  @2,   [16:17]  ;
Rcv_no_change_4aux:
    b    Rcv_no_change_4     @2,   [8:9]    ; Trick to fill timing

Rcv_Bytes_SyncErro: @ sync failed
    ldr   r2, =0
Rcv_Bytes_EOP_ERRO:
    pop   {r0, r1}
    ldr   r0, =0
    b    Rcv_Bytes_END

Rcv_Bytes_EOP:				 @
    strb   r0, [r1]          @2,   [5:6]
    subs   r1, #1            @1,   [7]     ; dec pointer
    bl   fDelay_5clk         @3+2, [8:12]   [ dummy to fill timing]
    bl   fDelay_5clk         @3+2, [13:17]  [ dummy to fill timing]
    ldrh   r7, [r6]          @2,   [0:1]    ; Read input (D- and D+)
    ands   r7, r3            @1,   [2]      ; Apply input pins mask
    bne  Rcv_Bytes_EOP_ERRO  @1/2, [3:3/4]  ; Branch if (D- and D+ == 0)
    bl   fDelay_5clk         @3+2, [4:8]
    bl   fDelay_5clk         @3+2, [9:13]
    bl   fDelay_5clk         @3+2, [14:18]
    ldrh   r7, [r6]          @2,   [0:1]    ; Read input (D- and D+)
    ldr    r4, =USB_DATA_J   @2,   [2:3]    ; State after EOP
    ands   r7, r3            @1,   [4]      ; Apply input mask
    cmp    r7, r4            @1,   [5]      ; Check state
    bne  Rcv_Bytes_EOP_ERRO  @1/2, [6:6/7]
#elif defined(__ARM_ARCH_7M__)
RCV_wait_sec_bit:
  #if defined(USB_DEBUG_PIN)
    movs.w r7, #(1 << (USB_DEBUG_PIN))      @ #DEBUG HIGH
    str.w  r7, [r11]                        @ #DEBUG
  #else
    nop.w                    @  [ dummy to fill timing]
    nop.w                    @  [ dummy to fill timing]
  #endif
    ldr    r12, [r9]         @ load countval
    add    r12, #34          @ delay for next sync bit

.align 3
Rcv_wait_sec_bit_delay:
    ldr    r7, [r9]
    subs   r7, r12
    blt   Rcv_wait_sec_bit_delay
  #if defined(USB_DEBUG_PIN)
    str.w  r0, [r11]         @ #DEBUG  LOW
  #else
    nop.w                    @  [ dummy to fill timing]
  #endif
Rcv_sync_sec_bit:
    ldrh   r7, [r6]          @2,   [0:1]    ; Read input (D- and D+)
    ands   r7, r2            @1,   [2]      ; Apply input mask
    cmp    r7, r4            @1,   [3]      ; Check if input changed
    bne  Rcv_Bytes_SyncErro  @1/2, [4:4/5]
    mov    r0, #30
    ldr    r5, =USB_DP_BITBANG
  #if defined(USB_DEBUG_PIN)
    movs.w r7, #(1 << (USB_DEBUG_PIN))   @ #DEBUG  HIGH
    str.w  r7, [r11]                     @ #DEBUG
  #else
    nop.w                    @  [ dummy to fill timing]
    nop.w                    @  [ dummy to fill timing]
  #endif

.align 3
Rcv_wait_third_bit:
    ldr.n  r7, [r5]          @2,   [0:1]    ; Read input (D- and D+)
    cbnz.n r7, Rcv_third_received
    subs.n r0, #1
    ldr.n  r7, [r5]
    cbnz.n r7, Rcv_third_received
    ldr.n  r7, [r5]
    cbnz.n r7, Rcv_third_received
    cbz.n  r0, Rcv_SyncErro
    ldr.n  r7, [r5]
    cbnz.n r7, Rcv_third_received
    b.n  Rcv_wait_third_bit

Rcv_SyncErro:
    b Rcv_Bytes_SyncErro

.align 3
Rcv_third_received:
    ldr    r12, [r9]         @ load countval
    add    r12, #30
  #if defined(USB_DEBUG_PIN)
    ldr.w  r0, =(1 << (16 + USB_DEBUG_PIN))    @ #DEBUG LOW
    str.w  r0, [r11]                           @ #DEBUG LOW
  #else
    nop.w                    @  [ dummy to fill timing]
    nop.w                    @  [ dummy to fill timing]
  #endif
    movs   r5, #4            @1,   [4]        ; Counter for remaining sync bits

.align 3
Rcv_sync_bits_loop: //----
    ldr    r7, [r9]
    subs   r7, r12
    blt   Rcv_sync_bits_loop

    ldr    r12, [r9]
    add    r12, #38     //---- delay for next
  #if defined(USB_DEBUG_PIN)
    movs.w r7, #(1 << (USB_DEBUG_PIN)) @ #DEBUG  HIGH
    str.w  r7, [r11]                   @ #DEBUG  HIGH
  #else
    nop.w                    @  [ dummy to fill timing]
    nop.w                    @  [ dummy to fill timing]
  #endif
    ldrh   r7, [r6]          @2,   [0:1]     ; Read input (D- and D+)
    ands   r7, r2            @1,   [2]      ; Apply input mask
    cmp    r7, r4            @1,   [3]      ; Check if input changed
    bne  Rcv_Bytes_SyncErro  @1/2, [4:4/5]
  #if defined(USB_DEBUG_PIN)
    str.w  r0, [r11]         @ #DEBUG  LOW
  #else
    nop.w                    @  [ dummy to fill timing]
  #endif
    mov    r7, r4            @1,   [5]      ; Swap [r3] and [r4]
    mov    r4, r3            @1,   [6]      ; For next sync bit check
    mov    r3, r7            @1,   [7]
    subs   r5, #1            @1,   [8]      ; dec remaining sync bits counter
    bne  Rcv_sync_bits_loop  @1/2, [10:10/11]

Rcv_last_sync_bit:
    ldr    r4, =DIFF_IC_MASK   @2,   [11:12]  ; Mask for incomming diff bits
    ldr    r5, =INI_L_ENC_DIFF @2,   ; Initial value of last enc.diff
    movs   r8, #0              @1,     ; [r8] Clear diff bits counter
    ldr    r10, =0xFFFF        @2,     ; [r10] const = 0xffff

.align 3
Rcv_last_sync_bit_delay:
    ldr    r7, [r9]
    subs   r7, r12
    blt  Rcv_last_sync_bit_delay

    ldr    r12, [r9]
    add    r12, #34
  #if defined(USB_DEBUG_PIN)
    movs.w r7, #(1 << (USB_DEBUG_PIN))   @ #DEBUG  HIGH
    str.w  r7, [r11]                     @ #DEBUG  HIGH
  #else
    nop.w                    @  [ dummy to fill timing]
    nop.w                    @  [ dummy to fill timing]
  #endif
    ldrh   r7, [r6]          @2,      ; Read input (D- and D+)
    tst    r7, r3            @1,     ; Check if input changed
    beq  Rcv_Bytes_SyncErro  @1/2,
    mov    r2, r3            @1,     ; [r2] State after sync (Data K)
    movs   r0, #0            @1,     ; [r0] Initial state of diff storage
    ldr    r3, =USB_DIMSK    @2,     ; [r3] Input pins mask
    mov    r10, #4

.align 3
Rcv_data_bits_delay:
    ldr    r7, [r9]              // ---------------
    subs   r7, r12
    blt  Rcv_data_bits_delay

.align 3
Rcv_data_bits_loop:
  #if defined(USB_DEBUG_PIN)
    ldr.w  r7, =(1 << (16 + USB_DEBUG_PIN))      @2 LOW [24/25]
    str.w  r7, [r11]                             @2 [26/27]
  #else
    ldr.w  r7, =0xffff       @2 [24/25]  [ dummy to fill timing]
    str.w  r7, [r6]          @2 [26/27]  [ dummy to fill timing]
  #endif
    ldr    r7, [r6]          @2,   [0:1]     ; Read input (D- and D+)
    ands   r7, r3            @1,   [2]      ; Apply input pins mask
    beq  Rcv_Bytes_EOP       @1/2, [3:3/4]  ; Branch if (D- and D+ == 0)
    add    r8, #1            @1,   [4]      ; inc diff bits counter
    tst    r7, r2            @1,   [5]      ; Check if Data state changed
    ittt   eq                @1,   [6]
     moveq   r2, r7          @1,   [7]      ; Update last input
     ldreq   r7, =0xffff     @2,   [8]
     eoreq   r5, r7          @1,   [10]      ; Invert last enc.diff
    ldr    r7, =DIFF_IC_MASK @2,   [11]  ; Mask for incomming diff bits
    ands   r5, r7            @1,   [13]     ; Mask new enc.diff
    lsrs   r0, #2            @1,   [14]     ; Shift to position
    orrs   r0, r5            @1,   [15]     ; Update enc.diff storage
  #if defined(USB_DEBUG_PIN)
    ldr.w  r7, =(1 << (USB_DEBUG_PIN))       @2 HIGH [28/29]
    str.w  r7, [r11]                         @2 [30/31]
  #else
    nop.w                   @2    [28/29]   [ dummy to fill timing]
    nop.w                   @2    [30/31]   [ dummy to fill timing]
  #endif
    nop.w                   @2  [ dummy to fill timing]
    nop                     @1  [ dummy to fill timing]
    subs   r10, #1          @1,   [16]     ; dec bits in byte counter (4bits)
    itttt  eq               @1,   [17]
     strbeq  r0, [r1]       @2,   [18]
     subeq   r1, #1         @1,   [20]     ; dec pointer
     moveq   r10, #4        @1,   [21]     ; reset bits in byte counter
     beq Rcv_data_bits_loop @2,   [22]
    b    Rcv_data_bits_loop @2,   [23]  ;

Rcv_Bytes_SyncErro: @ sync failed
  #if defined(USB_DEBUG_PIN)
    ldr    r7, =USB_DEBUG_BSRR
    ldr    r5, =(1 << (16+2))      @ LOW
    str    r5, [r7]                @
  #endif
  #if defined(USB_DEBUG_SYNC_EOP_ERROR)
    bkpt #1
  #endif
    pop    {r0, r1}
    movw   r0, #(-1 & 0xFFFF)
    b    Rcv_Bytes_END

Rcv_Bytes_EOP_ERRO1:
  #if defined(USB_DEBUG_SYNC_EOP_ERROR)
    bkpt #1
  #endif
    pop    {r0, r1}
    movw   r0, #(-2 & 0xFFFF)
    b    Rcv_Bytes_END

Rcv_Bytes_EOP_ERRO2:
  #if defined(USB_DEBUG_SYNC_EOP_ERROR)
    bkpt #1
  #endif
    pop    {r0, r1}
    movw   r0, #(-3 & 0xFFFF)
    b    Rcv_Bytes_END

Rcv_Bytes_EOP:				 @
    strb   r0, [r1]          @2,   [5:6]
    subs   r1, #1            @1,   [7]     ; dec pointer
    bl   fDelay_5clk         @3+2, [8:12]   [ dummy to fill timing]
    bl   fDelay_5clk         @3+2, [13:17]  [ dummy to fill timing]
  #if defined(USB_DEBUG_PIN)
    ldr.w  r7, =(1 << (USB_DEBUG_PIN))  @2 HIGH [28/29]
    str.w  r7, [r11]                    @2 [30/31]
  #else
    nop.w                    @2    [28/29]   [ dummy to fill timing]
    nop.w                    @2    [30/31]   [ dummy to fill timing]
  #endif
    ldr    r7, [r6]          @2,   [0:1]    ; Read input (D- and D+)
    ands   r7, r3            @1,   [2]      ; Apply input pins mask
    bne  Rcv_Bytes_EOP_ERRO1  @1/2, [3:3/4]  ; Branch if (D- and D+ == 0)
    bl   fDelay_5clk          @3+2, [4:8]
    bl   fDelay_5clk         @3+2, [9:13]
    bl   fDelay_5clk         @3+2, [14:18]
  #if defined(USB_DEBUG_PIN)
    ldr.w  r7, =(1 << (16 + USB_DEBUG_PIN))      @2 LOW [28/29]
    str.w  r7, [r11]                  @2 [30/31]
  #else
    nop.w                    @2    [28/29]   [ dummy to fill timing]
    nop.w                    @2    [30/31]   [ dummy to fill timing]
  #endif
    ldr    r7, [r6]          @2,   [0:1]    ; Read input (D- and D+)
    ldr    r4, =USB_DATA_J   @2,   [2:3]    ; State after EOP
    ands   r7, r3            @1,   [4]      ; Apply input mask
    cmp    r7, r4            @1,   [5]      ; Check state
    bne  Rcv_Bytes_EOP_ERRO2  @1/2, [6:6/7]
#endif
    pop	   {r4}			     @ param: (0) dont call ACK / (1) call ACK
    cmp    r4, #1
    bne  Rcv_Bytes_NoAck     @ branch if param No ACK
Rcv_Bytes_DoAck:
    ldr    r7, =USB_DIFF_ACK_PACKET
    rev    r7, r7
    push   {r7}              @ store in stack
    ldr    r0, =USB_DIFF_ACK_PACKET_LEN
    mov    r1, sp
    adds   r1, #3            @ Pointer to data
    bl	 Send_RawDiff
    pop    {r7}              @ back stact pointer

Rcv_Bytes_NoAck:
    mov    r0, r8            @ length diff bits
    mov    r1, sp
    subs   r1, #OFFSET_FROM_STACK   @ pointer to diff bits (reverse stored)
    pop	   {r2}			            @ pointer outArray Data decoded
    bl	 Rawdiff2Bytes
    b    Rcv_Bytes_END

Rcv_Bytes_END:
    CPSIE   i                @ enable interrups
    pop   {r4-r7}
    mov   r8, r4
    mov   r9, r5
    mov   r10, r6
    mov   r11, r7
    pop   {r4-r7, pc}
