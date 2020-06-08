#!/bin/sh
# Licensed under the zlib/libpng license (same as NSIS)
#
# Script to perform CPUID test
#
# Usage: run.sh [<helper dir [<Windows architecture> [<test dir>]]]

OUTPUT="output.log"
SCRIPT="cpuid_test.nsi"
SOURCEDIR=$(cd "$(dirname "$0")"; pwd -P)
TOPDIR=$(cd "${SOURCEDIR}/../.."; pwd -P)
HELPERDIR="${1:-"${TOPDIR}/build"}/helpers/${SOURCEDIR##*/}"

INSTALLER="${SCRIPT%.*}.exe"
UNINSTALLER="uninstall.exe"

. "${SOURCEDIR}/../common/funcs.sh"

before() {
	makeInstaller "-XOutFile ${PWD}/${INSTALLER}" \
		"-DCPUID_HELPER_DIR=${HELPERDIR}" \
		"${SOURCEDIR}/${SCRIPT}"
}

after() {
	[ -f "${OUTPUT}" ] && rm "${OUTPUT}"
	[ -f "${INSTALLER}" ] && rm "${INSTALLER}"
	[ -f "${UNINSTALLER}" ] && rm "${UNINSTALLER}"
}

runInstaller() {
	${WINE} ${INSTALLER} /S "/RESULT=${OUTPUT}" && tail -n 1 ${OUTPUT}
}

runUninstaller() {
	${WINE} ${UNINSTALLER} /S "/?=${PWD}" "/RESULT=${OUTPUT}" && tail -n 1 ${OUTPUT}
}

test_vendor_id() {
        echo "vendor id"
	for runner in Installer Uninstaller; do
		result=$(assert_equal "${1}" \
			$(eval run${runner}))
		echo "${result} (${runner})"
	done
}

main() {
	vendor_id=
	while read -r line
	do
		set -f -- safety $line
		shift
		if [ "${1}" = "vendor_id" ]; then
			vendor_id=${3}
			break
		fi
	done < /proc/cpuinfo
	if [ -n "${vendor_id}" ]; then
		test_vendor_id ${vendor_id}
	fi
}

[ $# -gt 1 ] && shift
wineSetUp "${@}"
if [ "${WINEARCH}" != "win32" ]; then
	echo "CPUID test requiring win32 Windows architecture is skipped"
else
	before
	main
	after
fi
wineCleanUp "${@}"
