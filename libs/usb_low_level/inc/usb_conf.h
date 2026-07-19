/**
  ******************************************************************************
  * @file           : usb_conf.h
  * @brief          : Header for usb configuration.
  *                   This file contains the common defines for usb.
  ******************************************************************************
  * @attention
  *
  ******************************************************************************
  */

/* Define to prevent recursive inclusion -------------------------------------*/
#ifndef __USB_CONF_H
#define __USB_CONF_H

/******************************************************************************/
/************************ Lib Configuration ***********************************/
/* Core frequency needed for USB receive and transfer timings ----------------*/
#define __FCPU__                24000000

/* USB gpio port base address of D- and D+ pins ------------------------------*/
#define USB_GPIO_BASE           GPIOA_BASE
#define USB_GPIO_D_MINUS_PIN    0
#define USB_GPIO_D_PLUS_PIN     1


/*----------------------------------------------------------------------------*/
/* Debug pin to assist on timing analyses ------------------------------------*/
//#define USB_DEBUG_PIN           2
//#define USB_DEBUG_GPIO          GPIOA_BASE

/* Insert brake point to sync and eop erro procedures ------------------------*/
//#define USB_DEBUG_SYNC_EOP_ERROR


/*----------------------------------------------------------------------------*/
/* Alias for (D-) (D+) defined pins ------------------------------------------*/
#define USB_DMP             USB_GPIO_D_MINUS_PIN
#define USB_DPP             USB_GPIO_D_PLUS_PIN

/*----------------------------------------------------------------------------*/
/* Device specific definitions -----------------------------------------------*/
#if defined(STM32F103xB)
    #define PERIPHERAL_BASE     0x40000000
    #define GPIOA_BASE          0x40010800
    #define GPIOB_BASE          0x40010C00
    #define GPIOC_BASE          0x40011000
    #define GPIOD_BASE          0x40011400
    #define GPIO_CRL_OFFSET     0x00
    #define GPIO_CRH_OFFSET     0x04
    #define GPIO_IDR_OFFSET     0x08
    #define GPIO_ODR_OFFSET     0x0C
    #define GPIO_BSRR_OFFSET    0x10
    #define GPIO_BRR_OFFSET     0x14
    #define GPIO_LCKR_OFFSET    0x18
    #define BIT_BANG_ALIAS_OFFSET   0x02000000
    #define DWT_CYCCNT          0xE0001004
    #define DWT_CTRL            0xE0001000
    #define DEMCR               0xE000EDFC

    #define BIT_BANG_BASE       PERIPHERAL_BASE + BIT_BANG_ALIAS_OFFSET
    #define USB_DP_BITBANG      BIT_BANG_BASE + ((USB_GPIO_IDR - PERIPHERAL_BASE) * 32) + (USB_DPP * 4)
    #define USB_GPIO_CRL        USB_GPIO_BASE + GPIO_CRL_OFFSET
    #define USB_GPIO_CRH        USB_GPIO_BASE + GPIO_CRH_OFFSET

/* Configuration for D- pin  -------------------------------------------------*/
#if (USB_DMP >= 0) && (USB_DMP <= 7)
    #define USB_DM_CRL_MSK      (0b1111 << (4 * USB_DMP))
    #define USB_DM_CRH_MSK       0
    #define USB_DM_CRL_OUT      (0b0011 << (4 * USB_DMP))
    #define USB_DM_CRH_OUT      0
    #define USB_DM_CRL_IN       (0b0100 << (4 * USB_DMP))
    #define USB_DM_CRH_IN       0
#elif (USB_DMP >= 8) && (USB_DMP <= 15)
    #define USB_DM_CRL_MSK      0
    #define USB_DM_CRH_MSK      (0b1111 << (4 * (USB_DMP-8)))
    #define USB_DM_CRL_OUT      0
    #define USB_DM_CRH_OUT      (0b0011 << (4 * (USB_DMP-8)))
    #define USB_DM_CRL_IN       0
    #define USB_DM_CRH_IN       (0b0100 << (4 * (USB_DMP-8)))
#else
    #error "USB_GPIO_D_MINUS_PIN : Out of range!"
#endif

/* Configuration for D+ pin  -------------------------------------------------*/
#if (USB_DPP >= 0) && (USB_DPP <= 7)
    #define USB_DP_CRL_MSK      (0b1111 << (4 * USB_DPP))
    #define USB_DP_CRH_MSK      0
    #define USB_DP_CRL_OUT      (0b0011 << (4 * USB_DPP))
    #define USB_DP_CRH_OUT      0
    #define USB_DP_CRL_IN       (0b0100 << (4 * USB_DPP))
    #define USB_DP_CRH_IN       0
#elif (USB_DPP >= 8) && (USB_DPP <= 15)
    #define USB_DP_CRL_MSK      0
    #define USB_DP_CRH_MSK      (0b1111 << (4 * (USB_DPP-8)))
    #define USB_DP_CRL_OUT      0
    #define USB_DP_CRH_OUT      (0b0011 << (4 * (USB_DPP-8)))
    #define USB_DP_CRL_IN       0
    #define USB_DP_CRH_IN       (0b0100 << (4 * (USB_DPP-8)))
#else
    #error "USB_GPIO_D_PLUS_PIN : Out of range!"
#endif

    #define USB_GPIO_CRL_MSK  ~(USB_DM_CRL_MSK | USB_DP_CRL_MSK)
    #define USB_GPIO_CRH_MSK  ~(USB_DM_CRH_MSK | USB_DP_CRH_MSK)
    #define USB_GPIO_CRL_OUT   (USB_DM_CRL_OUT | USB_DP_CRL_OUT)
    #define USB_GPIO_CRH_OUT   (USB_DM_CRH_OUT | USB_DP_CRH_OUT)
    #define USB_GPIO_CRL_IN    (USB_DM_CRL_IN | USB_DP_CRL_IN)
    #define USB_GPIO_CRH_IN    (USB_DM_CRH_IN | USB_DP_CRH_IN)

#elif defined(STM32G030xx)
    #define GPIOA_BASE          0x50000000
    #define GPIOB_BASE          0x50000400
    #define GPIOC_BASE          0x50000800
    #define GPIOD_BASE          0x50000C00
    #define GPIO_MODER_OFFSET   0x00
    #define GPIO_OTYPER_OFFSET  0x04
    #define GPIO_OSPEEDR_OFFSET 0x08
    #define GPIO_PUPDR_OFFSET   0x0C
    #define GPIO_IDR_OFFSET     0x10
    #define GPIO_ODR_OFFSET     0x14
    #define GPIO_BSRR_OFFSET    0x18
    #define GPIO_LCKR_OFFSET    0x1C
    #define GPIO_AFRL_OFFSET    0x20
    #define GPIO_AFRH_OFFSET    0x24
    #define GPIO_BRR_OFFSET     0x28

    #define USB_GPIO_MODER      USB_GPIO_BASE + GPIO_MODER_OFFSET
    #define USB_GPIO_OSPEEDR    USB_GPIO_BASE + GPIO_OSPEEDR_OFFSET
    #define USB_GPIO_OTYPER     USB_GPIO_BASE + GPIO_OTYPER_OFFSET
    #define USB_DM_MSM          (0b11 << (2 * USB_DMP))
    #define USB_DP_MSM          (0b11 << (2 * USB_DPP))
    #define USB_DM_OM           (0b01 << (2 * USB_DMP))
    #define USB_DP_OM           (0b01 << (2 * USB_DPP))
    #define USB_DM_IM           (0b00 << (2 * USB_DMP))
    #define USB_DP_IM           (0b00 << (2 * USB_DPP))
    #define USB_GPIO_MODE_SPEED_MASK  ~(USB_DM_MSM | USB_DP_MSM)
    #define USB_GPIO_HIGHSPEED  (USB_DM_MSM | USB_DP_MSM)  // use High Speed
    #define USB_GPIO_OUTPUT     (USB_DM_OM | USB_DP_OM)    // use Output mode
    #define USB_GPIO_INPUT      (USB_DM_IM | USB_DP_IM)
#endif

/*----------------------------------------------------------------------------*/
/* Definitions for operation*/
#define USB_DEBUG_BSRR      USB_DEBUG_GPIO + GPIO_BSRR_OFFSET
#define USB_GPIO_IDR        USB_GPIO_BASE + GPIO_IDR_OFFSET
#define USB_GPIO_ODR        USB_GPIO_BASE + GPIO_ODR_OFFSET
#define USB_GPIO_BSRR       USB_GPIO_BASE + GPIO_BSRR_OFFSET

#define USB_DM_SOH          (1 << USB_DMP)             // (D-) Set Output HIGH
#define USB_DM_SOL          (1 << (USB_DMP + 16))      // (D-) Set Output LOW
#define USB_DP_SOH          (1 << USB_DPP)             // (D+) Set Output HIGH
#define USB_DP_SOL          (1 << (USB_DPP + 16))      // (D+) Set Output LOW
#define USB_DIMSK           (1 << USB_DMP | 1<< USB_DPP)
#define USB_DIFF_1          (USB_DM_SOL | USB_DP_SOH)  // (D+)=1, (D-)=0
#define USB_DIFF_0          (USB_DM_SOH | USB_DP_SOL)  // (D+)=0, (D-)=1
#define USB_DATA_K          (1 << USB_DPP)             // State when DIFF_1
#define USB_DATA_J          (1 << USB_DMP)             // State when DIFF_0
#define USB_SE0             (USB_DM_SOL | USB_DP_SOL)  // (D+)=0, (D-)=0
#define USB_EOP             0


#endif /* __USB_CONF_H */