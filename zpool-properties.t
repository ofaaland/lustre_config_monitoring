#!/bin/bash
# check that ZFS pool properties are set as specified

export PATH=/bin:/usr/bin:/sbin:/usr/sbin

declare -r description="Check zfs pool properties"

# Source functions
source ${NODEDIAGDIR:-/etc/nodediag.d}/functions-tap || exit 1

diag_handle_args "$@"

pools=`zpool list -H | awk '{print $1}'`
[ -z "$pools" ] &&  diag_plan_skip "no ZFS pools" >&2

function verify_property {
	local fname="verify_property"
	local pool=$1
	local propname=$2
	local expectedval=$3

	if [ -z "$pool" ]; then
		echo "BUG: $fname missing argument pool" >&2
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

	propval=`zpool list -H -o ${propname} ${pool} 2>/dev/null`
	if [ "${propval}" != ${expectedval} ] ; then
		diag_fail "pool ${pool} property ${propname} is ${propval}, expected ${expectedval}" >&2
	else
		diag_ok "pool ${pool} property ${propname} is ${propval}" >&2
	fi
}

function handle_test {
	local fname="handle_test"
	local pool=$1
	local propname=$2
	local expectedval=$3
	local action=$4
	
	if [ -z "$action" ]; then
		echo "BUG: $fname missing argument action" >&2
		exit 1
	fi

	if [ "$action" = "count_tests" ] ; then
		num_tests=$((num_tests+1))
	else
		verify_property ${pool} ${propname} ${expectedval}
	fi
}

function foreach_pool_and_property {
	local action=$1

	for pool in ${pools}
	do
		for idx in ${!DIAG_ZPOOL_NAME[@]}
		do
			poolregex=${DIAG_ZPOOL_NAME[$idx]}

			if [[ ! ${pool} =~ ${poolregex} ]]; then
				continue
			fi

			handle_test ${pool} autoreplace ${DIAG_ZPOOL_AUTOREPLACE[$idx]} $action
			handle_test ${pool} multihost   ${DIAG_ZPOOL_MULTIHOST[$idx]}   $action
		done
	done
}

#
# number of tests
#
num_tests=0
foreach_pool_and_property count_tests
[ $num_tests -eq 0 ] &&  diag_plan_skip "no ZFS pool checks" >&2
diag_plan $num_tests

#
# Main
#

foreach_pool_and_property  do_tests
