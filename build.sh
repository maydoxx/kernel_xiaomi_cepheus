#!/bin/bash

# Exit immediately if a command fails (highly recommended for CI/CD)
set -e

KERNEL_DEFCONFIG=cepheus_defconfig
ANYKERNEL3_DIR="$PWD/AnyKernel3"
FINAL_KERNEL_ZIP=InfiniR_cepheus_v2.02_A16_KSUN.zip

# Use the workspace Clang if available, otherwise fallback to system path
if [ -d "$PWD/clang-aosp/bin" ]; then
    export PATH="$PWD/clang-aosp/bin:$PATH"
fi

export LLVM=1
export CC=clang
export CROSS_COMPILE=aarch64-linux-gnu-
export CROSS_COMPILE_ARM32=arm-linux-gnueabi-
export ARCH=arm64
export USE_CCACHE=1

# Initialize output folder
mkdir -p out

echo "**** Generating defconfig ****"
make O=out ARCH=arm64 $KERNEL_DEFCONFIG

START=$(date +"%s")

echo "**** Starting Kernel Compilation ****"
make ARCH=arm64 \
        O=out \
        CC=clang \
        AR=llvm-ar \
        LD=ld.lld \
        NM=llvm-nm \
        OBJCOPY=llvm-objcopy \
        OBJDUMP=llvm-objdump \
        STRIP=llvm-strip \
        -j$(nproc --all)

echo "**** Verify Image.gz-dtb ****"
ls "$PWD/out/arch/arm64/boot/Image.gz-dtb"

echo "**** Verifying AnyKernel3 Directory ****"
ls "$ANYKERNEL3_DIR"

echo "**** Removing leftovers ****"
rm -rf "$ANYKERNEL3_DIR/Image.gz-dtb"
rm -rf "$ANYKERNEL3_DIR/$FINAL_KERNEL_ZIP"

echo "**** Copying Image.gz-dtb ****"
cp "$PWD/out/arch/arm64/boot/Image.gz-dtb" "$ANYKERNEL3_DIR/"

echo "**** Time to zip up! ****"
cd "$ANYKERNEL3_DIR"
zip -r9 "$FINAL_KERNEL_ZIP" * -x README "$FINAL_KERNEL_ZIP"

# Copy the zip up to the main root workspace folder so GitHub Actions can find it easily
cp "$FINAL_KERNEL_ZIP" "../$FINAL_KERNEL_ZIP"

echo "**** Done, here is your checksum ****"
cd ..
sha1sum "$FINAL_KERNEL_ZIP"

END=$(date +"%s")
DIFF=$((END - START))
echo -e "\033[01;32mKernel compiled successfully in $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds\033[0m"
