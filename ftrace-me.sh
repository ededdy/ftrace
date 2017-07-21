#!/bin/bash
#
# A rudimentary tracing script to do function, function_graph and
# blk tracing for a process which is passed as an argument to this
# script.
#
# Author: Sougata Santra <sougata.santra@gmail.com>

set -ex

if test $(id -u) -ne 0; then
	echo >&2 "Running $0 requires root privilege. Aborting"
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

# Enable this for function and blk tracers.
# This filter is not supported for function_graph tracer
#
echo $$ > $DEBUGFS/tracing/set_ftrace_pid

# echo function > $DEBUGFS/tracing/current_tracer
# echo function_graph > $DEBUGFS/tracing/current_tracer

echo blk > $DEBUGFS/tracing/current_tracer
echo 1 > $DEBUGFS/tracing/events/block/enable
echo 1 > $DEBUGFS/tracing/options/latency-format

# Enable this only for function tracer.
#
#echo ':mod:<module-name>' > $DEBUGFS/tracing/set_ftrace_filter

cat $DEBUGFS/tracing/current_tracer

# Set this only for blk tracer.
cat $DEBUGFS/tracing/set_event

echo 1 > $DEBUGFS/tracing/tracing_on
echo "Trace Begin" > $DEBUGFS/tracing/trace_marker
process=$(exec $*)
echo "Trace End" > $DEBUGFS/tracing/trace_marker

# Copy trace to PWD
cat  $DEBUGFS/tracing/trace > $(pwd)/trace

# Reset trace parameters
echo nop > $DEBUGFS/tracing/current_tracer
echo > $DEBUGFS/tracing/set_ftrace_filter
echo > $DEBUGFS/tracing/set_ftrace_pid
echo 0 > $DEBUGFS/tracing/options/latency-format
echo 0 > $DEBUGFS/tracing/events/block/enable
echo 0 > $DEBUGFS/tracing/tracing_on

# Call the test-destructor
#	- umount volume
#	- rmmod module
bash test-epilogue.sh 
