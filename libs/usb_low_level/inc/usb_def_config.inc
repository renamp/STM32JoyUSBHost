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
#include "usb_conf.h"

/**
 * @brief  Consts
 */
.equ USB_SYNC_TIMEOUT,          0x100000
.equ USB_DIFF_ACK_PACKET,       0xA965A666
.equ USB_DIFF_ACK_PACKET_LEN,   16

.equ NUMBER_DIFF_BITS_IN_BYTE,  (0x04)
.equ DIFF_IC_MASK,              0xC0     // Incoming encoded diff mask
.equ INI_L_ENC_DIFF,            0x80     // Initial value for last enc.diff

.equ USB_TOKEN_PID_IN,          0x69
