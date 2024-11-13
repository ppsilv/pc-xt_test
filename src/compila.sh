#!/bin/bash

nasm -O9 -f bin -o pcxt_test.bin -l pcxt_bios.lst pcxt_test.asm
