#!/bin/sh
as syscalls.s -o syscalls.o && ld syscalls.o -o syscalls
