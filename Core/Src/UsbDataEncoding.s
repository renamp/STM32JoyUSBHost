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

#if defined(__ARM_ARCH_7M__)
  .cpu cortex-m3
#elif defined(__ARM_ARCH_6M__)
  .cpu cortex-m0plus
#endif

.syntax unified
.fpu softvfp
.thumb

.global Bytes2Rawdiff
.global Rawdiff2Bytes


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
.thumb_func
Bytes2Rawdiff:
    push    {r4-r7, lr}
    mov     r7, r8
    mov     r6, r9
    mov     r5, r10
    mov     r4, r11
    push    {r4-r7}

    mov     r11, sp         @ initial stack position
    mov     r7, sp
    subs    r7, #4          @ Alloc 4bytes in stack
    mov     sp, r7
    mov     r7, r11
    subs    r7, #1          @ (x) rawdiff output pointer (top of stack)
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
    bl    StoreByte
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
    bl   StoreByte
    mov     r0, r9          @ len diff bits
    mov     r1, r11         @ ptr stack before diff bits
    subs    r1, #1          @ ptr array diff
    bl    Send_RawDiff
    mov     sp, r11         @ restore stack
    pop     {r4-r7}         @ restore r10,r9,r8 into r5,r6,r7
    mov     r11, r4
    mov     r10, r5
    mov     r9, r6
    mov     r8, r7
    pop     {r4-r7, pc}         @ restore r4-r7

StoreByte:
    mov     r7, r8          @ [r7] load rawdiff pointer
	subs    r7, #1
    strb    r3, [r7]        @ store diff byte
    mov     r8, r7          @ [r8] update rawdiff pointer
    lsrs    r7, #2
    lsls    r7, #2          @ update current stack allocation
    mov     sp, r7
    bx lr


.equ NUMBER_DIFF_BITS_IN_BYTE,    (0x04)
.equ BITSTUFF_CNT_RST,            (0x06)
.equ INITIAL_DIFF,                (0x02)
.equ DIFF_MASK,                   (0x03)
.equ SET_BIT,                     (0x80)

/**
 * @brief  Converts an array of raw differential bits to data bytes.
 * @param  r0: Length of the input raw differential data in bits
 * @param  r1: Pointer to the raw differential data array(stored on the stack)
 * @param  r2: Pointer to the data array to store output bytes
 * @retval r0: Length of the output data in bytes
 * @note
 *
 */
.thumb_func
Rawdiff2Bytes:
    push  {r4-r7, lr}
    mov   r4, r8
    mov   r5, r9
    mov   r6, r10
    mov   r7, r11
    push  {r4-r7}
    movs  r7, #1          @
    mov   r12, r7         @ [r12] always 1 (for inc operations)
    movs  r7, #0
    mov   r8, r7          @ clear data bytes counter
    mov   r11, r7         @ clear (T)[r11] skip bitstuff
    mov   r6, r7          @ clear Decoding data byte
    movs  r7, 0x08
    mov   r9, r7          @ [r9] count data_bits
    ldr   r7, =NUMBER_DIFF_BITS_IN_BYTE
    mov   r10, r7         @ [r10] load number of differential bits
    ldr   r3, =BITSTUFF_CNT_RST  @ [r3] reset bitstuff counter
    ldr   r4, =INITIAL_DIFF      @ [r4] store Initial diff state
Rawdiff2BytesI0:
    ldrb  r5, [r1]        @ load to [r5] next packed bitstuff from array
    subs  r1, #1          @ update point to next element
Rawdiff2BytesI1:
    ldr   r7, =DIFF_MASK  @ Mask for next differential (D- and D+) respective
    ands  r7, r5          @ move masked bits to decode
    eors  r4, r7          @ check state of bits. if didnt change result==0
    mov   r4, r7          @ store actual state for next check
    bne  Rawdiff2BytesL1  @ branch if state changed
    lsrs  r6, #1
    subs  r3, #1          @ decrement bitstuff counter [r3]
    bne  Rawdiff2BytesL2  @ branch if not bitstuff
    mov   r11, r12        @ set (T)[r11] skip next bit. it is a bitstuffed
    ldr   r3, =BITSTUFF_CNT_RST
Rawdiff2BytesL2:
    ldr   r7, =SET_BIT    @ load set bit
    orrs  r6, r7          @ update current decoding data byte
    b    Rawdiff2BytesL3
Rawdiff2BytesS1:
    movs  r7, #0
    mov   r11, r7         @ clear (T)[r11] skip bitstuff
    b    Rawdiff2BytesL4
Rawdiff2BytesL1:
    mov   r7, r11
    ands  r7, r7
    bne  Rawdiff2BytesS1  @ it is bitstuff - goto skip bitstuff
    lsrs  r6, #1          @ update current decoding data byte
    ldr   r3, =BITSTUFF_CNT_RST
Rawdiff2BytesL3:          @ check number of bits
    mov   r7, r9          @ load data_bits counter
    subs  r7, #1          @ decrement
    mov   r9, r7          @ store data_bits counter back to [r9]
    bne  Rawdiff2BytesL4  @ branch when counter==0
    movs  r7, #0x08       @ counter data_bits reset value
    mov   r9, r7          @ store data_bits counter [r9]
    strb  r6, [r2]        @ store decoded data
    adds  r2, #1          @ Increment data pointer
    add   r8, r12         @ incremment decoded data counter [r8]
    movs  r6, #0          @ clear Decoding data byte
Rawdiff2BytesL4:          @ check diff len
    subs  r0, #1          @ decrement len diff bits
    beq  Rawdiff2BytesEND
    lsrs  r5, #2          @ rotate to next differential (D- and D+)
    mov   r7, r10         @ load counter differential bits in byte
    subs  r7, #1          @ decrement
    mov   r10, r7         @ store the counter back
    bne  Rawdiff2BytesI1
    ldr   r7, =NUMBER_DIFF_BITS_IN_BYTE            @
    mov   r10, r7
    b    Rawdiff2BytesI0
Rawdiff2BytesEND:
    mov   r0, r8          @ return len of decoded data bytes
    pop   {r4-r7}         @ restore r10,r9,r8 into r4,r5,r6
    mov   r8, r4
    mov   r9, r5
    mov   r10, r6
    mov   r11, r7
    pop   {r4-r7, pc}     @ restore r4-r7 and return
