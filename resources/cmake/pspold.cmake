#
# CMake toolchain file for PSP.
#
# Copyright 2019 - Wally
# Copyright 2020 - Daniel 'dbeef' Zalega

if (DEFINED PSPDEV)
    # Custom PSPDEV passed as cmake call argument.
else()
    # Determine PSP toolchain installation directory;
    # psp-config binary is guaranteed to be in path after successful installation:
    execute_process(COMMAND bash -c "psp-config --pspdev-path" OUTPUT_VARIABLE PSPDEV OUTPUT_STRIP_TRAILING_WHITESPACE)
endif()

# Assert that PSP SDK path is now defined:
if (NOT DEFINED PSPDEV)
    message(FATAL_ERROR "PSPDEV not defined. Make sure psp-config in your path or pass custom \
                        toolchain location via PSPDEV variable in cmake call.")
endif ()

# Set helper variables:
set(PSPSDK ${PSPDEV}/psp/sdk)
set(PSPBIN ${PSPDEV}/bin)
set(PSPCMAKE ${PSPDEV}/psp/share/cmake)

# Basic CMake Declarations
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR mips)
set(triple mipsel-unknown-linux)


set(CMAKE_C_COMPILER clang)
set(CMAKE_C_COMPILER_TARGET ${triple})

set(CMAKE_CXX_COMPILER clang++)
set(CMAKE_CXX_COMPILER_TARGET ${triple})
set(CMAKE_C_FLAGS "-mcpu=mips2 -msingle-float -mno-check-zero-division -D__psp__ -include clang_psp.h -fuse-ld=lld -nostdlib -L$PSPDEV/psp/lib -Wl,--no-dynamic-linker")

set(CMAKE_FIND_ROOT_PATH "${PSPSDK};${PSPDEV}")
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

# Set paths to PSP-specific utilities:
set(MKSFO ${PSPBIN}/mksfo)
set(MKSFOEX ${PSPBIN}/mksfoex)
set(PACK_PBP ${PSPBIN}/pack-pbp)
set(FIXUP ${PSPBIN}/psp-fixup-imports)
set(ENC ${PSPBIN}/PrxEncrypter)
set(STRIP ${PSPBIN}/psp-strip)

# Include directories:
add_definitions("-D__psp__ -mcpu=mips2 -msingle-float -mno-check-zero-division -include clang_psp.h -fuse-ld=lld -nostdlib -L$PSPDEV/psp/lib -Wl,--no-dynamic-linker")
include_directories( SYSTEM /usr/mipsel-sony-psp/psp/include /usr/mipsel-sony-psp/psp/sdk/include)
# Discard debug information:
#add_definitions("-G0")

# Definitions that may be needed to use some libraries:
add_definitions("-D__PSP__")
#add_definitions("-DHAVE_OPENGL")

# Aggregated list of all PSP-specific libraries for convenience.
set(PSP_LIBRARIES
        "-lg -lc -lpspdebug -lpspctrl -lpspsdk \
        -lpspnet -lpspnet_inet -lpspnet_apctl -lpspnet_resolver -lpspaudiolib \
        -lpsputility -lGL \
        -lpspvfpu -lpspdisplay -lpsphprm -lpspirkeyb \
        -lpsprtc -lpspaudio -lpspvram  -lpspgu -lpspge -lpspuser \
        -L${PSPSDK}/lib -L${PSPDEV}/lib"
)

# File defining macro outputting PSP-specific EBOOT.PBP out of passed executable target:
#include("${PSPCMAKE}/CreatePBP.cmake")

# Helper variable for multi-platform projects to identify current platform:
set(PLATFORM_PSP TRUE BOOL)
