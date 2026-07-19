cmake_minimum_required(VERSION 3.22)

add_library(usb_low_level OBJECT)
target_sources(usb_low_level PRIVATE 
    src/UsbDataEncoding.S
    src/Usb_signal_transfer_timing.S
    src/Usb_signal_receive.S
    src/usb_util.S
    src/usb_crc.S
)
target_include_directories(usb_low_level PUBLIC 
    inc
)

target_link_libraries(usb_low_level PRIVATE 
    stm32cubemx
)
