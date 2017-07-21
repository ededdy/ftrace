#!/bin/bash
#
# A rudimentary tracing script to do function stack trace, to
# check all the callers of the function.
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
echo function > $DEBUGFS/tracing/current_tracer

# To use the function tracer backtrace feature, it is imperative that the
# functions being called are limited by the function filters. The option to
# enable the function backtracing is unique to the function tracer and
# activating it can only be done when the function tracer is enabled. This
# means you must first enable the function tracer before you have access to the
# option:

echo $1 > $DEBUGFS/tracing/set_ftrace_filter
cat $DEBUGFS/tracing/set_ftrace_filter
echo 1 > $DEBUGFS/tracing/options/func_stack_trace

echo 1 > $DEBUGFS/tracing/tracing_on
echo "Trace Begin" > $DEBUGFS/tracing/trace_marker
process=$(exec $2 $3)
echo "Trace End" > $DEBUGFS/tracing/trace_marker

# Copy trace to PWD
cat  $DEBUGFS/tracing/trace > $(pwd)/trace

# Reset trace parameters
echo 0 > $DEBUGFS/tracing/tracing_on
echo 0 > $DEBUGFS/tracing/options/func_stack_trace
echo > $DEBUGFS/tracing/set_ftrace_filter
echo nop > $DEBUGFS/tracing/current_tracer
# Call the test-destructor
#	- umount volume
#	- rmmod module
bash test-epilogue.sh 
