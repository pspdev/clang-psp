#!/bin/bash 

#PSP Development Toolchain deployment script
#Copyright PSPDev Team 2020 and designed by Wally
#This script is designed to be deployed automatically via CI, new binaries are offered via CI

#TODO Fetch ncurses-dev / libusb-1.0 and readline-dev packages zlib

CLANG_VER="10" ## Change this when a new version of llvm / clang becomes avaliable 
BASE_DIR="$PWD"
BUILD_DIR="$BASE_DIR/build"
RUST_URL="https://github.com/overdrivenpotato/rust-psp"
PSPSDK_URL="https://github.com/wally4000/pspsdk" #This is temporary until the SDK is stable and we can merge back to base
NEWLIB_URL="https://github.com/overdrivenpotato/newlib"
PSPLINK_URL="https://github.com/pspdev/psplinkusb"

PREFIX="$BASE_DIR/mipsel-sony-psp"
PSPDEV=$PREFIX
PSPSDK=$PREFIX/psp/sdk
PATH=$PATH:$PSPDEV/bin

function fetch_clang
{
    bash -c "$(wget -O - https://apt.llvm.org/llvm.sh)"

    # LLVM & Clang
    apt-get -y install libllvm-$CLANG_VER-ocaml-dev libllvm$CLANG_VER llvm-$CLANG_VER llvm-$CLANG_VER-dev llvm-$CLANG_VER-doc llvm-$CLANG_VER-examples llvm-$CLANG_VER-runtime
    apt-get -y install clang-$CLANG_VER clang-tools-$CLANG_VER clang-$CLANG_VER-doc libclang-common-$CLANG_VER-dev libclang-$CLANG_VER-dev libclang1-$CLANG_VER clang-format-$CLANG_VER python-clang-$CLANG_VER clangd-$CLANG_VER
    # libfuzzer, lldb, lld (linker), libc++, OpenMP
    apt-get -y install libfuzzer-$CLANG_VER-dev lldb-$CLANG_VER lld-$CLANG_VER libc++-$CLANG_VER-dev libc++abi-$CLANG_VER-dev libomp-$CLANG_VER-dev

    apt-get -y install git texi2html 
}

function prep_sources
{
    mkdir build; cd build
    git clone $RUST_URL --depth=1
    git clone $PSPSDK_URL --depth=1
    git clone $NEWLIB_URL -b newlib-3_20_0-PSP --depth=1
    git clone $PSPLINK_URL --depth=1

    mkdir -p "$PREFIX/psp/share"
    mkdir "$PREFIX/bin"
}

## Configure Rust - This will fall into root
function fetch_rust
{
    curl https://sh.rustup.rs -sSf | sh -s -- -y

    export PATH=$PATH:$HOME/.cargo/bin
    source $HOME/.cargo/env
    rustup set profile minimal
    rustup toolchain install nightly-2020-07-02
    rustup default nightly-2020-07-02 && rustup component add rust-src
    rustup update
    cargo install cargo-psp xargo
}

function compile_libpsp
{
    cat << EOF > $BUILD_DIR/rust-psp/psp/Xargo.toml
    [target.mipsel-sony-psp.dependencies.core]
    [target.mipsel-sony-psp.dependencies.alloc]
    [target.mipsel-sony-psp.dependencies.panic_unwind]
    stage = 1
EOF

    cd $BUILD_DIR/rust-psp/psp
    xargo rustc --features stub-only --target mipsel-sony-psp -- -C opt-level=3 -C panic=abort
    cd $BUILD_DIR
}

function populateSDK
{
    cd $BUILD_DIR/pspsdk
    ./bootstrap
    mkdir build; cd build
    ../configure PSP_CC=clang PSP_CFLAGS="--config $PREFIX/psp/sdk/lib/clang.conf" PSP_CXX=clang++ PSP_AS=llvm-as PSP_LD=ld.lld PSP_AR=llvm-ar PSP_NM=llvm-nm PSP_RANLIB=llvm-ranlib --with-pspdev=$PREFIX --disable-sonystubs --disable-psp-graphics --disable-psp-libc
    make -j$(nproc) install-data
    cd $BUILD_DIR
}

function fetch_newlib
{
cd $BUILD_DIR/newlib
mkdir build && cd build
CC=clang-$CLANG_VER ../configure AR_FOR_TARGET=llvm-ar-$CLANG_VER AS_FOR_TARGET=llvm-as-$CLANG_VER RANLIB_FOR_TARGET=llvm-ranlib-$CLANG_VER CC_FOR_TARGET=clang-$CLANG_VER CXX_FOR_TARGET=clang++-$CLANG_VER --target=psp --enable-newlib-iconv --enable-newlib-multithread --enable-newlib-mb --prefix=$PREFIX
make -j$(nproc)
make -j$(nproc) install
cd $BUILD_DIR
}

function compileSDK
{
    cd $BUILD_DIR/pspsdk/build
    make -j$(nproc) 
    make -j$(nproc) install
    cd $BUILD_DIR
    cp -r "$BASE_DIR/resources/cmake" "$PREFIX/psp/share"
    cp "$HOME/.cargo/bin/pack-pbp" "$PREFIX/bin"
    cp "$HOME/.cargo/bin/mksfo" "$PREFIX/bin"
    cp "$BUILD_DIR/rust-psp/target/mipsel-sony-psp/debug/libpsp.a" "$PREFIX/psp/sdk/lib"
    cd $BUILD_DIR
}

function fetch_psplink
{
    ## Will fail if libusb 1.0 is not present
    clang-$CLANG_VER psplinkusb/usbhostfs_pc/main.c -Ipsplinkusb/usbhostfs  -DPC_SIDE -D_FILE_OFFSET_BITS=64 -lusb -lpthread -o $PREFIX/bin/usbhostfs_pc
    clang++-$CLANG_VER psplinkusb/pspsh/*.c -Ipsplinkusb/psplink -D_PCTERM -lreadline -lcurses -o $PREFIX/bin/pspsh
}

function fetch_libraries
{
    ## Fetches PSP Libraries

    git clone https://github.com/take-cheeze/pthreads-emb/ --depth=1

    ## Installs Libraries
    cd pthreads-emb
make -C platform/psp -j$(nproc) && make -C platform/psp install
cp -v *.h `psp-config --psp-prefix`/include

##libcxx
## Fetch llvm
## cd build-libcxx
## cmake -DCMAKE_TOOLCHAIN_FILE=$PSPDEV/psp/share/cmake/PSP.cmake -DLIBCXX_ENABLE_SHARED=0 -DLIBCXX_HAS_PTHREAD_API=1 -DCMAKE_INSTALL_PREFIX=$PSPDEV/psp ../libcxx
}


#fetch_clang
prep_sources
fetch_rust
compile_libpsp
populateSDK
fetch_newlib
compileSDK
#fetch_psplink
fetch_libraries
