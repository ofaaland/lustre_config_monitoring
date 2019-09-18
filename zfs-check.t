#!/bin/bash
###########################################################################
# $URL: file:///var/svn/cfengine3/operating_systems/toss/3/tut/toss-check.t $
# $Author: faaland1 $
# $Date: 2018-10-17 14:16:09 -0700 (Wed, 17 Oct 2018) $
# $Rev: 14610 $
###########################################################################

# check that node is running correct toss version, yum groups,
# and installed rpms are correct

export PATH=/bin:/usr/bin:/sbin:/usr/sbin


declare -r description="Check zfs dataset properties"

# Source functions
source ${NODEDIAGDIR:-/etc/nodediag.d}/functions-tap || exit 1

diag_handle_args "$@"

# dont run if no zfs gender
#( ! nodeattr -v zfs ) && diag_plan_skip "not configured"

# find lustre datasets
datasets=`zfs list -o name,lustre:svname -H | awk '$2 != "-" {print $1}'`
[ -z "$datasets" ] &&  diag_plan_skip "no lustre datasets" >&2

# number of tests
diag_plan "2"

#
# Main
#

# For datasets:
# with property lustre:svname

# Need to test:
# dnodesize=auto
# xatttr=sa
# canmount=off
# recordsize=(128K on MDTs, 1M on OSTs, 128K on MGS)

for dataset in ${datasets}
do
	# Maybe unnecessary
	# target_type=`zfs list -o lustre:svname -H $dataset | sed 's/^.*-//' | cut -c 1-3 | tr [:upper:] [:lower:]`
	# [ -z "$target_type" ] && diag_skip "unable to parse lustre target name" >&2
	# [ $target_type != "mgs" -a $target_type != "mdt" -a $target_type != "ost" ] &&  diag_skip "unrecognized lustre target type" >&2

	if [ -n "${DIAG_ZFS_RECORDSIZE}" ] ; then
		recordsize=`zfs list -H -o recordsize ${dataset}`
		if [ ${recordsize} != ${DIAG_ZFS_RECORDSIZE} ] ; then
			diag_fail "recordsize ${recordsize}, expected ${DIAG_ZFS_RECORDSIZE}" >&2
		else
			diag_ok "recordsize ${recordsize} OK" >&2
		fi
	fi

	if [ -n "${DIAG_ZFS_DNODESIZE}" ] ; then
		dnodesize=`zfs list -H -o dnodesize ${dataset}`
		if [ ${dnodesize} != ${DIAG_ZFS_DNODESIZE} ] ; then
			diag_fail "dnodesize ${dnodesize}, expected ${DIAG_ZFS_DNODESIZE}" >&2
		else
			diag_ok "dnodesize ${dnodesize} OK" >&2
		fi
	fi

	if [ -n "${DIAG_ZFS_XATTR}" ] ; then
		xattr=`zfs list -H -o xattr ${dataset}`
		if [ ${xattr} != ${DIAG_ZFS_XATTR} ] ; then
			diag_fail "xattr ${xattr}, expected ${DIAG_ZFS_XATTR}" >&2
		else
			diag_ok "xattr ${xattr} OK" >&2
		fi
	fi

	if [ -n "${DIAG_ZFS_CANMOUNT}" ] ; then
		canmount=`zfs list -H -o canmount ${dataset}`
		if [ ${canmount} != ${DIAG_ZFS_CANMOUNT} ] ; then
			diag_fail "canmount ${canmount}, expected ${DIAG_ZFS_CANMOUNT}" >&2
		else
			diag_ok "canmount ${canmount} OK" >&2
		fi
	fi
done
