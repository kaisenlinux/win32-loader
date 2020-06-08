#!/bin/sh
# Licensed under the zlib/libpng license (same as NSIS)
#
# Script to perform system information tests
#
# Usage: run.sh [<helper dir [<Windows architecture> [<test dir>]]]

OUTPUT="output.log"
SCRIPT="sysinfo_test.nsi"
SOURCEDIR=$(cd "$(dirname "$0")"; pwd -P)
TOPDIR=$(cd "${SOURCEDIR}/../.."; pwd -P)
HELPERDIR=${1:-"${TOPDIR}/build"}

INSTALLER="${SCRIPT%.*}.exe"

. "${SOURCEDIR}/../common/funcs.sh"

before() {
	makeInstaller "-XOutFile ${PWD}/${INSTALLER}" \
		"${SOURCEDIR}/${SCRIPT}"
}

after() {
	[ -f "${OUTPUT}" ] && rm "${OUTPUT}"
	[ -f "${INSTALLER}" ] && rm "${INSTALLER}"
}

runInstaller() {
	${WINE} ${INSTALLER} /S "${1}" "/RESULT=${OUTPUT}" && tail -n 1 ${OUTPUT}
}

test_it() {
	if [ $# -gt 1 ]; then
		t="${2}"
		echo "${t}"
		result=$(assert_equal "${1}" $(runInstaller "/TEST=${t}"))
		echo "${result}"
	fi
}

test_Domain() {
        t="Domain"
	domain=$(hostname -d 2>/dev/null)
	if [ -n "${domain}" ]; then
		test_it "${domain}" "${t}"
	else
		echo ${t}
		echo "No domain name"
		echo "SKIPPED"
	fi
}

test_HostName() {
        t="HostName"
	test_it "$(hostname -s)" "${t}"
}

test_KeyboardLayout() {
        t="KeyboardLayout"
	layout="0x0000"
	if [ -n "${DISPLAY}" ]; then
		# United States - English (0x409)
		layout="0x0409"
	fi
	test_it "${layout}" "${t}"
}

test_UserName() {
        t="UserName"
	test_it "$(logname 2>/dev/null || echo ${LOGNAME})" "${t}"
}

main() {
	for t in Domain HostName KeyboardLayout UserName; do
		eval test_${t}
	done
}

[ $# -gt 1 ] && shift
wineSetUp "${@}"
before
main
after
wineCleanUp "${@}"
