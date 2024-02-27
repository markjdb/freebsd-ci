#!/bin/sh

TARGET=amd64
TARGET_ARCH=amd64

CROSS_TOOLCHAIN=amd64-gcc12

export MAKEOBJDIRPREFIX=/tmp/obj
rm -fr ${MAKEOBJDIRPREFIX}

MAKECONF=${MAKECONF:-/dev/null}
SRCCONF=${SRCCONF:-/dev/null}

cd ${WORKSPACE}/src

make -j ${BUILDER_JFLAG} -DNO_CLEAN \
	buildworld \
	TARGET=${TARGET} \
	TARGET_ARCH=${TARGET_ARCH} \
	CROSS_TOOLCHAIN=${CROSS_TOOLCHAIN} \
	__MAKE_CONF=${MAKECONF} \
	SRCCONF=${SRCCONF}
make -j ${BUILDER_JFLAG} -DNO_CLEAN \
	buildkernel \
	TARGET=${TARGET} \
	TARGET_ARCH=${TARGET_ARCH} \
	CROSS_TOOLCHAIN=${CROSS_TOOLCHAIN} \
	__MAKE_CONF=${MAKECONF} \
	SRCCONF=${SRCCONF}
