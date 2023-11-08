#!/bin/sh
as main.s -o ./build/main.o && ld ./build/main.o -o ./build/server
