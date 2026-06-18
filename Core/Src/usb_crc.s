/**
  ******************************************************************************
  * @file      usb_crc.s  [16/6/2026]
  * @author    Renan A. Pacheco
  * @brief   Software implemented crc checks
  *     This module:
  *         - CRC-5 for Tocken packets
  *         - CRC-16 for data pachects
  *
  ******************************************************************************
  */


.global USB_crc16
.global USB_AppendCRC5


.equ CRC16_INI,         0xFFFF
.equ CRC16_POLY,        0xA001
.equ CRC5_POLY,         0x14        ; poly = 10100
.equ CRC5_INIMASK,      0x1F

/**
 * @brief  CRC-16 for USB data packet
 *
 * @param  r0: len (data array length)
 *         r1: ptr_data
 * @retval  CRC-16
 * @note
 *    prototype:
 *      extern uint16_t USB_crc16(uint8_t len, uint8_t *ptr_data);
 */
.thumb_func
USB_crc16:
    adds    r1, #1          @ skip pid byte (first)
    subs    r0, #1          @ dec length
    bne    usb_crc16_l0
    ldr     r0, =0
    bx lr
usb_crc16_l0:
    push    {r4, r5}
    ldr     r2, =CRC16_INI  @ crc = 0xFFFF
usb_crc16_l1:
    ldrb    r3, [r1]
    adds    r1, #1
    movs    r5, #8          @ Bit counter
usb_crc16_l2:
    mov     r4, r2          @ (crc) XOR (data bit)
    eors    r4, r3
    lsrs    r2, #1
    lsrs    r4, #1          @ Shift to poly test using carry
    bcc   usb_crc16_no_poly
    ldr     r4, =CRC16_POLY
    eors    r2, r4
usb_crc16_no_poly:
    lsrs    r3, #1          @ Next data bit
    subs    r5, #1
    bne   usb_crc16_l2
    subs    r0, #1
    bne   usb_crc16_l1
    ldr     r3, =0xFFFF
    subs    r3, r2          @ Final invert (One complement)
    mov     r0, r3          @ return crc-16
    pop     {r4, r5}
    bx      lr


/**
 * @brief  Calculate and Append CRC-5 to USB token
 *
 * @param  r0: pointer to USBToken struct type
 * @retval  CRC-5
 * @note
 *    prototype:
 *      extern void USB_AppendCRC5(USBToken *data);
 * USBToken {[0:8]pid, [0:6]Addr|[7:10]endpont|[11:15]CRC}
 */
.thumb_func
USB_AppendCRC5:
    push   {r4-r7}
    ldr     r1, [r0]        @ Read token
    lsrs    r1, #8          @ Rotate to exclude first byte (pid)
    movs    r6, #CRC5_INIMASK  @ init = 11111
    movs    r5, #11
crc5_01:
    mov	    r7, r6          @ cpy to r7
    eors    r7, r1
    lsrs    r1, #1
    lsrs    r6, #1
    lsrs    r7, #1
    bcc   crc5_02
    movs    r7, #CRC5_POLY
    eors    r6, r7		    @ xor with poly
crc5_02:
    subs    r5, #1
    bne   crc5_01
    movs    r7, #0xff
    ands    r6, r7
    subs    r7, r6          @ One complement
    movs    r6, #CRC5_INIMASK
    ands    r6, r7
    mov     r1, r6
    lsls    r6, #3          @ Shift returned crc5
    movs    r7, 0xF8
    ands    r6, r7          @ CRC5 last 5 bits
    ldrb    r2, [r0, #2]
    movs    r7, 0x7
    ands    r2, r7          @ First 3 bits are from endpoint
    orrs    r2, r6
    strb    r2, [r0, #2]    @ Append CRC5 to Token array
    pop   {r4-r7}
    bx lr
