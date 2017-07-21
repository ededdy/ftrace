#!/bin/bash
#
# A rudimentary tracing script to do function graph, to
# check all the functions that the given function calls.
#
# Author: Sougata Santra <sougata.santra@gmail.com>

set -ex

if test $(id -u) -ne 0; then
	echo >&2 "Running $0 requires root privilege. Aborting"
	exit 1
fi

echo "Total arguments"$#

if test $# -ne 3; then
	echo >&2 "Usage $0 <function-name> bash run-test.sh"
	exit 1
fi

if test -z $1; then
	exit 1
fi

# Call the test-constructor.
#	- format volume
#	- insmod module (unless the module is insmoded the corresponding
#		functions and events won't be available in debug-fs.
#	- mount volume
bash test-prologue.sh

DEBUGFS=/sys/kernel/debug
echo 0 > $DEBUGFS/tracing/tracing_on
echo nop > $DEBUGFS/tracing/current_tracer
echo $1 > $DEBUGFS/tracing/set_graph_function
echo function_graph > $DEBUGFS/tracing/current_tracer

echo 1 > $DEBUGFS/tracing/tracing_on
echo "Trace Begin" > $DEBUGFS/tracing/trace_marker
process=$(exec $2 $3)
echo "Trace End" > $DEBUGFS/tracing/trace_marker

# Copy trace to PWD
cat  $DEBUGFS/tracing/trace > $(pwd)/trace

# Reset trace parameters
echo 0 > $DEBUGFS/tracing/tracing_on
echo nop > $DEBUGFS/tracing/current_tracer
echo > $DEBUGFS/tracing/set_graph_function
# Call the test-destructor
#	- umount volume
#	- rmmod module
bash test-epilogue.sh 
