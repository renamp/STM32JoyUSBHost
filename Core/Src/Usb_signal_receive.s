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

.syntax unified
.cpu cortex-m0plus
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
    movs   r7, #NUMBER_DIFF_BITS_IN_BYTE
    mov    r11, r7           @  ; [r11] reset value for diff bits counters
Rcv_wait_first_bit:
    ldrh   r7, [r6]          @2,   [0:1]    ; Read input (D- and D+)
    ands   r7, r2            @1,   [2]
    cmp    r7, r3            @1,   [3]      ; Check if input changed
    beq  RCV_sync_bits       @1/2, [4:4/5]
    subs   r5, #1            @1,   [5]      ; dec timeout
    beq  Rcv_Bytes_SyncErro  @1/2, [6]
    ldrh   r7, [r6]          @2,   [0:1]    ; Read input (D- and D+)
    ands   r7, r2            @1,   [2]
    cmp    r7, r3            @1,   [3]      ; check if input changed
    bne  Rcv_wait_first_bit  @1/2, [4:4/5]
RCV_sync_bits:
    ldr    r7, =1            @2,   [5:6]    ;
    mov    r12, r7           @1,   [7]      ; [r12] always 1 to inc counters
    movs   r5, #6            @1,   [8]      ; counter for remaining sync bits
    ldr    r0, =0            @2,   [9:10]   [ dummy to fill timing]
    nop                      @1,   [11]     [ dummy to fill timing]
    ldr    r0, =0            @2,   [12:13]  [ dummy to fill timing]
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
    nop                      @1,   [14]     [ dummy to fill timing]

    ldrh   r7, [r6]          @2,   [0:1]    ; Read input (D- and D+)
    ldr    r4, =USB_DATA_J   @2,   [2:3]    ; State after EOP
    ands   r7, r3            @1,   [4]      ; Apply input mask
    cmp    r7, r4            @1,   [5]      ; Check state
    bne  Rcv_Bytes_EOP_ERRO  @1/2, [6:6/7]

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
    pop	   {r2}			     @ pointer outArray Data decoded
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
