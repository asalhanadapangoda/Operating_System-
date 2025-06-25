#!/bin/sh

qemu-system-i386 -drive format=raw,file=disk_images/asalos.flp,index=0,if=floppy
