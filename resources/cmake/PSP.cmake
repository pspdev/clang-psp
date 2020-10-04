set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR mips)

set(triple mips-unknown-linux)
set (CMAKE_SYSROOT $ENV{PSPDEV}/psp)


set(CMAKE_C_COMPILER clang)
set(CMAKE_C_COMPILER_TARGET ${triple})
set(CMAKE_CXX_COMPILER clang++)
set(CMAKE_CXX_COMPILER_TARGET ${triple})

set(CMAKE_C_FLAGS "--config $ENV{PSPSDK}/lib/clang.conf")
set(CMAKE_CXX_FLAGS "--config $ENV{PSPSDK}/lib/clang.conf" )

