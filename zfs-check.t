#!/bin/bash
# check that ZFS dataset properties are set as specified

export PATH=/bin:/usr/bin:/sbin:/usr/sbin

declare -r description="Check zfs dataset properties"

# Source functions
source ${NODEDIAGDIR:-/etc/nodediag.d}/functions-tap || exit 1

diag_handle_args "$@"

datasets=`zfs list -H | awk '{print $1}'`
[ -z "$datasets" ] &&  diag_plan_skip "no lustre datasets" >&2

num_datasets=$(echo $datasets | wc -w)
num_tests=0
[ -n "${DIAG_ZFS_RECORDSIZE}" ]  && num_tests=$((num_tests+1))
[ -n "${DIAG_ZFS_DNODESIZE}" ]  && num_tests=$((num_tests+1))
[ -n "${DIAG_ZFS_XATTR}" ]  && num_tests=$((num_tests+1))
[ -n "${DIAG_ZFS_CANMOUNT}" ]  && num_tests=$((num_tests+1))

# number of tests
diag_plan $((num_tests * num_datasets))

#
# Main
#

for dataset in ${datasets}
do
	# Maybe unnecessary
	# target_type=`zfs list -o lustre:svname -H $dataset | sed 's/^.*-//' | cut -c 1-3 | tr [:upper:] [:lower:]`
	# [ -z "$target_type" ] && diag_skip "unable to parse lustre target name" >&2
	# [ $target_type != "mgs" -a $target_type != "mdt" -a $target_type != "ost" ] &&  diag_skip "unrecognized lustre target type" >&2

	if [ -n "${DIAG_ZFS_RECORDSIZE}" ] ; then
		recordsize=`zfs list -H -o recordsize ${dataset} 2>/dev/null`
		if [ "${recordsize}" != ${DIAG_ZFS_RECORDSIZE} ] ; then
			diag_fail "dataset ${dataset} recordsize ${recordsize}, expected ${DIAG_ZFS_RECORDSIZE}" >&2
		else
			diag_ok "dataset ${dataset} recordsize ${recordsize} OK" >&2
		fi
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
