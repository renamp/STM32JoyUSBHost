/**
  ******************************************************************************
  * @file      usb_def_conf.s  [15/6/2026]
  * @author    Renan A. Pacheco
  * @brief     PORT and PINs configuration and definitions
  *
  ******************************************************************************
  * @attention
  *     - Pins must be from same PORT
  ******************************************************************************
  */


/**
 * @brief  PORT and PINS used for (D-) and (D+)
 */
.equ USB_GPIO_BASE,             0x50000000
.equ USB_GPIO_D_MINUS_PIN,      0
.equ USB_GPIO_D_PLUS_PIN,       1

.equ USB_SYNC_TIMEOUT,         (0x100000)


.equ USB_GPIO_MODER,      USB_GPIO_BASE + 0x00
.equ USB_GPIO_PUPDR,      USB_GPIO_BASE + 0x0C
.equ USB_GPIO_IDR,        USB_GPIO_BASE + 0x10
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
.equ USB_DM_IM,           (0b00 << (2 * USB_DMP))
.equ USB_DP_IM,           (0b00 << (2 * USB_DPP))
.equ USB_GPIO_INPUT,      (USB_DM_IM | USB_DP_IM)
.equ USB_DIMSK,           (1 << USB_DMP | 1<< USB_DPP)
.equ USB_GPIO_HIGHSPEED,  (USB_DM_MSM | USB_DP_MSM)  // use High Speed
.equ USB_DIFF_1,          (USB_DM_SOL | USB_DP_SOH)  // (D+)=1, (D-)=0
.equ USB_DIFF_0,          (USB_DM_SOH | USB_DP_SOL)  // (D+)=0, (D-)=1
.equ USB_DATA_K,          (1 << USB_DPP)         // Data-K state when DIFF_1
.equ USB_DATA_J,          (1 << USB_DMP)         // Data-J state when DIFF_0
.equ USB_SE0,             (USB_DM_SOL | USB_DP_SOL)  // (D+)=0, (D-)=0
.equ USB_EOP,             0
.equ USB_DIFF_ACK_PACKET, (0xA965A666)
.equ USB_DIFF_ACK_PACKET_LEN, 16

/**
 * @brief  Consts
 */
.equ OFFSET_FROM_STACK,         40
.equ NUMBER_DIFF_BITS_IN_BYTE,  (0x04)
.equ DIFF_IC_MASK,              0xC0     // Incoming encoded diff mask
.equ INI_L_ENC_DIFF,            0x80     // Initial value for last enc.diff
