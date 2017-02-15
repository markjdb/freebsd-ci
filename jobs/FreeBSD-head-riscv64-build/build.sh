#!/bin/sh

IMAGE_NAME=riscv.img
JOB_BASE=${WORKSPACE}/freebsd-ci/jobs/${JOB_NAME}

TARGET=riscv
TARGET_ARCH=riscv64

export MAKEOBJDIRPREFIX=${WORKSPACE}/obj
rm -fr ${MAKEOBJDIRPREFIX}
export DESTDIR=${WORKSPACE}/dest
rm -fr ${DESTDIR}

MAKECONF=${MAKECONF:-/dev/null}
SRCCONF=${SRCCONF:-/dev/null}

cd ${WORKSPACE}/src

make -j ${BUILDER_JFLAG} \
	-DNO_CLEAN \
	CROSS_TOOLCHAIN=riscv64-gcc \
	TARGET=${TARGET} \
	TARGET_ARCH=${TARGET_ARCH} \
	buildworld

make CROSS_TOOLCHAIN=riscv64-gcc \
	TARGET=${TARGET} \
	TARGET_ARCH=${TARGET_ARCH} \
	-DNO_CLEAN \
	-DNO_ROOT \
	-DWITHOUT_TESTS \
	DESTDIR=${DESTDIR} \
	installworld
make CROSS_TOOLCHAIN=riscv64-gcc \
	TARGET=${TARGET} \
	TARGET_ARCH=${TARGET_ARCH} \
	-DNO_CLEAN \
	-DNO_ROOT \
	-DWITHOUT_TESTS \
	DESTDIR=${DESTDIR} \
	distribution

cd ${WORKSPACE}
src/tools/tools/makeroot/makeroot.sh -s 32m -f ${JOB_BASE}/basic.files ${IMAGE_NAME} ${DESTDIR}

cd ${WORKSPACE}/src

cat ${JOB_BASE}/QEMUTEST | sed -e "s,%%MFS_IMAGE%%,${WORKSPACE}/${IMAGE_NAME}," | tee sys/riscv/conf/QEMUTEST
make -j ${BUILDER_JFLAG} \
	-DNO_CLEAN \
	CROSS_TOOLCHAIN=riscv64-gcc \
	TARGET=${TARGET} \
	TARGET_ARCH=${TARGET_ARCH} \
	KERNCONF=QEMUTEST \
	MODULES_OVERRIDE='' \
	WITHOUT_FORMAT_EXTENSIONS=yes \
	buildkernel

cat ${JOB_BASE}/SPIKETEST | sed -e "s,%%MFS_IMAGE%%,${WORKSPACE}/${IMAGE_NAME}," | tee sys/riscv/conf/SPIKETEST
make -j ${BUILDER_JFLAG} \
	-DNO_CLEAN \
	CROSS_TOOLCHAIN=riscv64-gcc \
	TARGET=${TARGET} \
	TARGET_ARCH=${TARGET_ARCH} \
	KERNCONF=SPIKETEST \
	MODULES_OVERRIDE='' \
	WITHOUT_FORMAT_EXTENSIONS=yes \
	buildkernel

cd ${WORKSPACE}
ARTIFACT_DEST=artifact/${FBSD_BRANCH}/r${SVN_REVISION}/${TARGET}/${TARGET_ARCH}
rm -fr ${ARTIFACT_DEST}
mkdir -p ${ARTIFACT_DEST}

xz ${IMAGE_NAME}
mv ${IMAGE_NAME}.xz ${ARTIFACT_DEST}

KERNEL_QEMU_FILE=${MAKEOBJDIRPREFIX}/${TARGET}.${TARGET_ARCH}${WORKSPACE}/src/sys/QEMUTEST/kernel
mv ${KERNEL_QEMU_FILE} ${KERNEL_QEMU_FILE}-qemu
xz ${KERNEL_QEMU_FILE}-qemu
mv ${KERNEL_QEMU_FILE}-qemu.xz ${ARTIFACT_DEST}

KERNEL_SPIKE_FILE=${MAKEOBJDIRPREFIX}/${TARGET}.${TARGET_ARCH}${WORKSPACE}/src/sys/SPIKETEST/kernel
mv ${KERNEL_SPIKE_FILE} ${KERNEL_SPIKE_FILE}-spike
xz ${KERNEL_SPIKE_FILE}-spike
mv ${KERNEL_SPIKE_FILE}-spike.xz ${ARTIFACT_DEST}

echo "SVN_REVISION=${SVN_REVISION}" > ${WORKSPACE}/trigger.property
