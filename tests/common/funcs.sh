#!/bin/sh
# Licensed under the zlib/libpng license (same as NSIS)
#
# Common functions for running tests

MAKENSIS=makensis
OLDPWD="${PWD}"
WINE=wine
WINEARCH=
WINEDIR=.wine
WINEPREFIX=

# Set up wine environment
# Parameters:
#   arch - optional architecture to be used with Wine, default value is win32
#   workdir - optional working directory
#             If not provided then a new temporary directeroy is
#             going to be created.
wineSetUp() {
	WINEARCH=${1:-win32}
	WORKDIR="${2}"
	err=0
	if [ -n "${WORKDIR}" ]; then
		cd "${WORKDIR}"
	else
		cd $(mktemp -d)
	fi
	${WINE} --version >/dev/null 2>&1
	err=$?
	if [ ${err} -ne 0 ]; then
		# wine is not available
		err=2
	else
		WINEPREFIX="${PWD}/${WINEDIR}"
		export WINEARCH WINEPREFIX
		${WINE} wineboot
		err=$?
		if [ ${err} -ne 0 ]; then
			# wineboot failed
			err=95
		else
			for sig in ALRM HUP INT QUIT TERM USR1; do
				trap "wineCleanUp; after; trap - $sig EXIT; exit 1" "$sig"
			done
		fi
	fi
	return ${err}
}

# Clean up wine environment of current working directory in case
# no working directory parameter was passed on
# Parameters:
#   arch - optional architecture to be used with Wine, defaults to win32
#   workdir - optional working directory to keep
wineCleanUp() {
	WORKDIR="${2}"
	if [ -z "${WORKDIR}" -a -d "${WINEDIR}" ]; then
		# Wait until the currently running wineserver terminates
		wineserver --wait
		rm -r ${WINEDIR}
		TESTDIR=${PWD}
		if [ "${TESTDIR}" != "${OLDPWD}" ]; then
			# Switch back to old working directory
			cd "${OLDPWD}"
			# If temporary test directory is empty then delete it
			if [ -z "$(ls -A "${TESTDIR}")" ]; then
				rmdir ${TESTDIR}
			fi
		fi
	fi
}

assert_equal() {
	if [ "${1}" != "${2}" ]; then
		echo "${1} != ${2}"
		echo "FAIL"
		exit 1
	else
		echo "OK"
	fi
}

mapArchitecture() {
	case ${WINEARCH} in
		win32)
			echo "-XTarget x86-unicode"
			;;
		win64)
			echo "-XTarget amd64-unicode"
			;;
		*)
			echo ""
			;;
	esac
}

makeInstaller() {
	(cd "${TOPDIR}" && ${MAKENSIS} -NOCD "$(mapArchitecture)" "$@") \
	|| exit
}
