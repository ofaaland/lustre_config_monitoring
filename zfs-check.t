#!/bin/bash
# check that ZFS dataset properties are set as specified

export PATH=/bin:/usr/bin:/sbin:/usr/sbin

declare -r description="Check zfs dataset properties"

# Source functions
source ${NODEDIAGDIR:-/etc/nodediag.d}/functions-tap || exit 1

diag_handle_args "$@"

datasets=`zfs list -H | awk '{print $1}'`
[ -z "$datasets" ] &&  diag_plan_skip "no ZFS datasets" >&2

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

num_datasets=$(echo $datasets | wc -w)
num_tests=0
[ -n "${DIAG_ZFS_RECORDSIZE[0]}" ]  && num_tests=$((num_tests+1))
[ -n "${DIAG_ZFS_DNODESIZE[0]}" ]  && num_tests=$((num_tests+1))
[ -n "${DIAG_ZFS_XATTR[0]}" ]  && num_tests=$((num_tests+1))
[ -n "${DIAG_ZFS_CANMOUNT[0]}" ]  && num_tests=$((num_tests+1))
[ -n "${DIAG_ZFS_COMPRESSION[0]}" ]  && num_tests=$((num_tests+1))

# number of tests
diag_plan $((num_tests * num_datasets))

#
# Main
#

for dataset in ${datasets}
do
	for idx in ${!DIAG_ZFS_DATASET_NAME[@]}
	do
		dsetglob=${DIAG_ZFS_DATASET_NAME[$idx]}

		if [[ ! ${dataset} =~ ${dsetglob} ]]; then
			continue
		fi

		if [ -n "${DIAG_ZFS_RECORDSIZE[$idx]}" ] ; then
			verify_property ${dataset} recordsize ${DIAG_ZFS_RECORDSIZE[$idx]}
		fi

		if [ -n "${DIAG_ZFS_DNODESIZE[$idx]}" ] ; then
			verify_property ${dataset} dnodesize ${DIAG_ZFS_DNODESIZE[$idx]}
		fi

		if [ -n "${DIAG_ZFS_XATTR[$idx]}" ] ; then
			verify_property ${dataset} xattr ${DIAG_ZFS_XATTR[$idx]}
		fi

		if [ -n "${DIAG_ZFS_CANMOUNT[$idx]}" ] ; then
			verify_property ${dataset} canmount ${DIAG_ZFS_CANMOUNT[$idx]}
		fi

		if [ -n "${DIAG_ZFS_COMPRESSION[$idx]}" ] ; then
			verify_property ${dataset} compression ${DIAG_ZFS_COMPRESSION[$idx]}
		fi
	done
	echo >&2
done
