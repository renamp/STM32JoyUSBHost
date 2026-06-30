/**
  ******************************************************************************
  * @file           : device_wrapper.h
  * @brief          : Header for device_wrapper.c file.
  *                   This file is a wrapper for device functions to be used
  *                   externally.
  ******************************************************************************
  * @attention
  ******************************************************************************
  */

/* Define to prevent recursive inclusion -------------------------------------*/
#ifndef __DEVICE_WRAPPER_H
#define __DEVICE_WRAPPER_H

#ifdef __cplusplus
extern "C" {
#endif

#include "main.h"


extern void _fDelay(uint32_t cycledelay);


void fUSB_Delay_1us();

void fUSB_Delay_10ms();



#ifdef __cplusplus
}
#endif

#endif /* __DEVICE_WRAPPER_H */
