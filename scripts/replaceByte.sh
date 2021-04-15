#!/bin/bash

cat $1 | while read line;
do
	printf '\x00\x20' | dd conv=notrunc of=$2 bs=1 seek=$(($line))
done