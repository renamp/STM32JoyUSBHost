/**
  ******************************************************************************
  * @file           : device_wrapper.c
  * @brief          : 
  *                   Wrapper for device functions to be used by USB Host
  *                   
  ******************************************************************************
  * @attention
  ******************************************************************************
  */

#include "../Inc/device_wrapper.h"


inline void fUSB_Delay_1us(){
    _fDelay(8);
}

inline void fUSB_Delay_10ms(){
    HAL_Delay(10);
}
