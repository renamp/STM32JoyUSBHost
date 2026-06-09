/**
  ******************************************************************************
  * @file      UsbDataEncoding.s  [9/6/2026]
  * @author    Renan A. Pacheco
  * @brief     Data encoding and decoding for USB communication
  *     This module performs:
  *         - Conversion of data bytes to raw differential format for 
  *           USB transmission
  *         - Handling of bit stuffing for USB communication protocol
  ******************************************************************************
  * @attention
  *
  ******************************************************************************
  */

.syntax unified
.cpu cortex-m0plus
.fpu softvfp
.thumb

.global Bytes2Rawdiff
.type Bytes2Rawdiff, %function

/**
 * @brief  Converts an array of data bytes to raw differential format for 
 *         USB transmission.
 * @param  r0: Length of the input data array (number of bytes)
 * @param  r1: Pointer to the input data array
 * @retval r0: Length of the output raw differential data in bits
 *         r1: Pointer to the output raw differential data (stored on the stack)
 *              !!(the pointer is stored on the stack in reverse order, 
 *              caller must read decrementally)!!
 * @note   
 *     
 */
Bytes2Rawdiff:
    push    {r4-r7}
    mov     r7, r8
    mov     r6, r9
    mov     r5, r10
    push    {r5-r7}

    mov     r7, sp
    subs    r7, #4          @ (x) rawdiff output pointer (top of stack)
    movs    r6, #0x66       @ load sync(Low nibble)
    strb    r6, [r7]
    movs    r6, #0xA6       @ load sync(High nibble)
    subs    r7, #1
    strb    r6, [r7]
    mov     r8 , r7         @ [r8] save rawdiff pointer

    movs    r6, #0x5
    mov     r12, r6         @ [r12] count 1s(start with 1)
	movs	r3, #0x00		@ current diff byte
	movs	r4, #0x03		@ diff bits mask
	movs	r5, #0xAA		@ previous diff state
    movs    r6, #0x08
	mov		r9, r6		    @ [r9] outLendiff bits
Bytes2Rawdiff_L0:
	ldrb	r2, [r1]		@ [r2] load byte from data in
    adds    r1, #1          @ inc data pointer
	movs	r6, #0x08	    @ [r6] count bits in byte
	mov		r10, r6         @ [r10] bits of byte
Bytes2Rawdiff_L1:
	lsrs	r2, #1			@ rotate to carry
	bcs	Bytes2Rawdiff_L3    @ branch if bit is 1
Bytes2Rawdiff_L2:
	movs	r6, #0xFF       @ set 0xFF
	eors	r5, r6		    @ change diff
	movs	r6, #0x07		@ reset bitstuff
    mov     r12, r6         @ [r12] update bitstuff count
Bytes2Rawdiff_L3:
    mov     r6, r9
    adds    r6, #1          @ inc len diff bits
    mov     r9, r6          @ [r9] update len diff bits
	mov		r6, r5
	ands	r6, r4			@ mask bits
	orrs	r3, r6			@ store diff
	lsls	r4, #2			@ shift mask
    movs    r6, #0xFF
    ands    r4, r6          @ mask diff bits
	bne	Bytes2Rawdiff_L4    @ jump if dont need store
    mov     r7, r8          @ [r7] load rawdiff pointer
	subs    r7, #1
    strb    r3, [r7]        @ store diff byte
    mov     r8, r7          @ [r8] update rawdiff pointer
    movs    r3, #0x00       @ reset current diff byte
    movs    r4, #0x03       @ reset diff bits mask
Bytes2Rawdiff_L4:
    mov     r6, r12
    subs    r6, #1          @ dec bitstuff count
    mov     r12, r6         @ [r12] update bitstuff count
	beq	Bytes2Rawdiff_L2    @ add bitstuff (0)
    mov     r6, r10         @ 
	subs	r6, #1		    @ bits of byte
    mov		r10, r6         @ [r10] update bits of byte
	bne	Bytes2Rawdiff_L1
	subs	r0, #1			@ bytes in array in
	bne	Bytes2Rawdiff_L0
    mov     r0, r9          @ len diff bits
    mov     r1, sp         
    subs    r1, #4          @ ptr array diff
    pop     {r5-r7}         @ restore r10,r9,r8 into r5,r6,r7
    mov     r10, r5
    mov     r9, r6
    mov     r8, r7
    pop     {r4-r7}         @ restore r4-r7
    bx      lr
