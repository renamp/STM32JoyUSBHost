###############################################################################
# CROSS-PLATFORM AUTOMATIC STM32 MCU Packages FETCHING
###############################################################################
include(FetchContent)

# 1. Detect OS and set the matching STM32Cube/Repository home path
if(CMAKE_HOST_WIN32)
    # Windows path: C:/Users/<User>/STM32Cube/Repository
    file(TO_CMAKE_PATH "$ENV{USERPROFILE}" USER_HOME)
else()
    # Linux/macOS path: /home/<User>/STM32Cube/Repository
    file(TO_CMAKE_PATH "$ENV{HOME}" USER_HOME)
endif()

set(CUBE_REPO_DIR "${USER_HOME}/STM32Cube/Repository")

# 2. Setup G0 Package
FetchContent_Declare(
    stm32cube_g0_pkg
    GIT_REPOSITORY "https://github.com/STMicroelectronics/STM32CubeG0.git"
    GIT_TAG        v1.6.3
    GIT_SUBMODULES "Drivers/CMSIS" "Drivers/STM32G0xx_HAL_Driver"
    SOURCE_DIR     "${CUBE_REPO_DIR}/STM32Cube_FW_G0_V1.6.3"
)
FetchContent_MakeAvailable(stm32cube_g0_pkg)

# 3. Setup F1 Package
FetchContent_Declare(
    stm32cube_f1_pkg
    GIT_REPOSITORY "https://github.com/STMicroelectronics/STM32CubeF1.git"
    GIT_TAG        v1.8.5
    GIT_SUBMODULES "Drivers/CMSIS" "Drivers/STM32F1xx_HAL_Driver"
    SOURCE_DIR     "${CUBE_REPO_DIR}/STM32Cube_FW_F1_V1.8.5"
)
FetchContent_MakeAvailable(stm32cube_f1_pkg)

# 4. Force override the path for the current project build
set(STM32_CUBE_PATH "${CUBE_REPO_DIR}/STM32Cube_FW_G0_V1.6.3" CACHE PATH "" FORCE)

###############################################################################
