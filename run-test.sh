#!/bin/bash

set -ex

time dd if=/dev/zero of=/mnt/tmp/test bs=1M count=10
