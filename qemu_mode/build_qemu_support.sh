#!/bin/sh
#
# american fuzzy lop - QEMU build script
# --------------------------------------
#
# Written by Andrew Griffiths <agriffiths@google.com> and
#            Michal Zalewski <lcamtuf@google.com>
#
# Copyright 2015 Google Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# This script downloads, patches, and builds a version of QEMU with
# minor tweaks to allow non-instrumented binaries to be run under
# afl-fuzz. 
#
# The modifications reside in patches/*. The standalone QEMU binary
# will be written to ../afl-qemu-trace.
#

echo "================================================="
echo "AFL binary-only instrumentation QEMU build script"
echo "================================================="
echo

echo "[*] Performing basic sanity checks..."

if [ ! "`uname -s`" = "Linux" ]; then

  echo "[-] Error: QEMU instrumentation is supported only on Linux."
  exit 1

fi

if [ ! -f "patches/afl-qemu-cpu-inl.h" -o ! -f "../config.h" ]; then

  echo "[-] Error: key files not found - wrong working directory?"
  exit 1

fi

if [ ! -f "../afl-showmap" ]; then

  echo "[-] Error: ../afl-showmap not found - compile AFL first!"
  exit 1

fi


for i in libtool wget python automake autoconf sha384sum bison iconv; do

  T=`which "$i" 2>/dev/null`

  if [ "$T" = "" ]; then

    echo "[-] Error: '$i' not found, please install first."
    exit 1

  fi

done

if [ ! -d "/usr/include/glib-2.0/" -a ! -d "/usr/local/include/glib-2.0/" ]; then

  echo "[-] Error: devel version of 'glib2' not found, please install first."
  exit 1

fi

if echo "$CC" | grep -qF /afl-; then

  echo "[-] Error: do not use afl-gcc or afl-clang to compile this tool."
  exit 1

fi

echo "[+] All checks passed!"

#echo "[+] Successfully created '../afl-qemu-trace'."
#
#echo "[*] Testing the build..."
#
#cd ..
#
#make >/dev/null || exit 1
#
#gcc test-instr.c -o test-instr || exit 1
#
#unset AFL_INST_RATIO
#
#echo 0 | ./afl-showmap -m none -Q -q -o .test-instr0 ./test-instr || exit 1
#echo 1 | ./afl-showmap -m none -Q -q -o .test-instr1 ./test-instr || exit 1
#
#rm -f test-instr
#
#cmp -s .test-instr0 .test-instr1
#DR="$?"
#
#rm -f .test-instr0 .test-instr1
#
#if [ "$DR" = "0" ]; then
#
#  echo "[-] Error: afl-qemu-trace instrumentation doesn't seem to work!"
#  exit 1
#
#fi
#
#echo "[+] Instrumentation tests passed. "

echo "[+] Building CGC qemu!"

QEMU_DIR=qemu-cgc-afl
rm -rf $QEMU_DIR
echo "[*] Cloning our QEMU repository..."
git clone git@git.seclab.cs.ucsb.edu:cgc/qemu.git $QEMU_DIR || exit 1
echo "[*] Checking out our current afl pre-patched QEMU version..."
git -C $QEMU_DIR checkout afl || exit 1
git -C $QEMU_DIR pull || exit 1
echo "[+] Checked out."

echo "[*] Attempting to merge in driller's changes"

echo "[*] Configuring QEMU..."

cd $QEMU_DIR || exit 1

./cgc_configure_opt

echo "[+] Configuration complete."

echo "[*] Attempting to build QEMU (fingers crossed!)..."

make -j || exit 1

echo "[+] Build process successful!"

echo "[*] Copying binary..."

mkdir -p ../../tracers/i386
cp -f "i386-linux-user/qemu-i386" "../../tracers/i386/afl-qemu-trace" || exit 1

cd ..
ls -l ../../tracers/i386/afl-qemu-trace || exit 1

echo "[+] Successfully created '../../tracers/i386/afl-qemu-trace'."

echo "[+] All set, you can now use the -Q mode in afl-fuzz on CGC binaries!"

exit 0
