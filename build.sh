#!/bin/bash
set -e

KERNEL_DEFCONFIG=cepheus_defconfig
ANYKERNEL3_DIR="$PWD/AnyKernel3"
FINAL_KERNEL_ZIP=InfiniR_cepheus_v2.02_A16_KSUN.zip

# Fallback cross-compiler prefix configuration for legacy build systems
export ARCH=arm64
export SUBARCH=arm64
export CROSS_COMPILE=aarch64-linux-android-
export CROSS_COMPILE_ARM32=arm-linux-androideabi-
export CC=clang
export CLANG_TRIPLE=aarch64-linux-gnu-

# Ensure output workspace folder is fresh
rm -rf out
mkdir -p out

echo "**** Generating defconfig ****"
make O=out ARCH=arm64 CROSS_COMPILE=aarch64-linux-android- CLANG_TRIPLE=aarch64-linux-gnu- $KERNEL_DEFCONFIG

START=$(date +"%s")

echo "**** Starting Kernel Compilation ****"
# Completely flattened arguments into one solid block to remove bad line endings/spaces
make ARCH=arm64 O=out CC=clang CLANG_TRIPLE=aarch64-linux-gnu- CROSS_COMPILE=aarch64-linux-android- CROSS_COMPILE_ARM32=arm-linux-androideabi- AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip -j$(nproc --all)

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
cd "$ANYKERNEL3_DIR" || exit 1
zip -r9 "$FINAL_KERNEL_ZIP" * -x README "$FINAL_KERNEL_ZIP"

# Save zip directly into the root repo directory
cp "$FINAL_KERNEL_ZIP" "../$FINAL_KERNEL_ZIP"

echo "**** Done, here is your checksum ****"
cd ..
sha1sum "$FINAL_KERNEL_ZIP"

END=$(date +"%s")
DIFF=$((END - START))
echo "Kernel compiled successfully in $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds"#!/bin/bash
# build.sh

set -e

KERNEL_DEFCONFIG=cepheus_defconfig
ANYKERNEL3_DIR="$PWD/AnyKernel3"
FINAL_KERNEL_ZIP=InfiniR_cepheus_v2.02_A16_KSUN.zip

# Ensure the out directory exists
mkdir -p out

# Build the configuration with explicit cross-compile targets
echo "**** Generating defconfig ****"
make O=out ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- CLANG_TRIPLE=aarch64-linux-gnu- $KERNEL_DEFCONFIG

START=$(date +"%s")

echo "**** Starting Kernel Compilation ****"
make ARCH=arm64 \
        O=out \
        CC=clang \
        CLANG_TRIPLE=aarch64-linux-gnu- \
        CROSS_COMPILE=aarch64-linux-gnu- \
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
cd "$ANYKERNEL3_DIR" || exit 1
zip -r9 "$FINAL_KERNEL_ZIP" * -x README "$FINAL_KERNEL_ZIP"

# Move the finished zip to the root of the workspace so the action can grab it
cp "$FINAL_KERNEL_ZIP" "../$FINAL_KERNEL_ZIP"

echo "**** Done, here is your checksum ****"
cd ..
sha1sum "$FINAL_KERNEL_ZIP"

END=$(date +"%s")
DIFF=$((END - START))
echo "Kernel compiled successfully in $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds"
