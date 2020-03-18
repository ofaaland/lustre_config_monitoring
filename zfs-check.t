#!/bin/bash
# check that ZFS dataset properties are set as specified

export PATH=/bin:/usr/bin:/sbin:/usr/sbin

declare -r description="Check zfs dataset properties"

# Source functions
source ${NODEDIAGDIR:-/etc/nodediag.d}/functions-tap || exit 1

diag_handle_args "$@"

datasets=`zfs list -H | awk '{print $1}'`
[ -z "$datasets" ] &&  diag_plan_skip "no ZFS datasets" >&2

num_datasets=$(echo $datasets | wc -w)
num_tests=0
[ -n "${DIAG_ZFS_RECORDSIZE}" ]  && num_tests=$((num_tests+1))
[ -n "${DIAG_ZFS_DNODESIZE}" ]  && num_tests=$((num_tests+1))
[ -n "${DIAG_ZFS_XATTR}" ]  && num_tests=$((num_tests+1))
[ -n "${DIAG_ZFS_CANMOUNT}" ]  && num_tests=$((num_tests+1))
[ -n "${DIAG_ZFS_COMPRESSION}" ]  && num_tests=$((num_tests+1))

# number of tests
diag_plan $((num_tests * num_datasets))

#
# Main
#

function verify_property {
	local fname="verify_property"
	local dataset=$1
	local propname=$2
	local expectedval=$3

	if [ -z "$dataset" ]; then
		echo "BUG: $fname missing argument dataset" >&2
		exit 1
	fi

	if [ -z "$propname" ]; then
		echo "BUG: $fname missing argument propname" >&2
		exit 1
	fi

	if [ -z "$expectedval" ]; then
		echo "BUG: $fname missing argument expectedval" >&2
		exit 1
	fi

	propval=`zfs list -H -o ${propname} ${dataset} 2>/dev/null`
	if [ "${propval}" != ${expectedval} ] ; then
		diag_fail "dataset ${dataset} property ${propname} is ${propval}, expected ${expectedval}" >&2
	else
		diag_ok "dataset ${dataset} property ${propname} is ${propval}" >&2
	fi
}

verify_property mds/mdt1 recordsize 128K

for dataset in ${datasets}
do
	if [ -n "${DIAG_ZFS_RECORDSIZE[0]}" ] ; then
		verify_property ${dataset} recordsize ${DIAG_ZFS_RECORDSIZE[0]}
	else
		echo "No check indicated for DIAG_ZFS_RECORDSIZE"
	fi

	if [ -n "${DIAG_ZFS_DNODESIZE}" ] ; then
		dnodesize=`zfs list -H -o dnodesize ${dataset} 2>/dev/null`
		if [ "${dnodesize}" != ${DIAG_ZFS_DNODESIZE} ] ; then
			diag_fail "dataset ${dataset} dnodesize ${dnodesize}, expected ${DIAG_ZFS_DNODESIZE}" >&2
		else
			diag_ok "dataset ${dataset} dnodesize ${dnodesize} OK" >&2
		fi
	else
		echo "No check indicated for DIAG_ZFS_DNODESIZE"
	fi

	if [ -n "${DIAG_ZFS_XATTR}" ] ; then
		xattr=`zfs list -H -o xattr ${dataset} 2>/dev/null`
		if [ "${xattr}" != ${DIAG_ZFS_XATTR} ] ; then
			diag_fail "dataset ${dataset} xattr ${xattr}, expected ${DIAG_ZFS_XATTR}" >&2
		else
			diag_ok "dataset ${dataset} xattr ${xattr} OK" >&2
		fi
	else
		echo "No check indicated for DIAG_ZFS_XATTR"
	fi

	if [ -n "${DIAG_ZFS_CANMOUNT}" ] ; then
		canmount=`zfs list -H -o canmount ${dataset} 2>/dev/null`
		if [ "${canmount}" != ${DIAG_ZFS_CANMOUNT} ] ; then
			diag_fail "dataset ${dataset} canmount ${canmount}, expected ${DIAG_ZFS_CANMOUNT}" >&2
		else
			diag_ok "dataset ${dataset} canmount ${canmount} OK" >&2
		fi
	else
		echo "No check indicated for DIAG_ZFS_CANMOUNT"
	fi
done
