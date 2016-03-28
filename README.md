# Driller-AFL

This repository holds some custom changes to AFL which hope to optimize AFL's performance on CGC binaries.
These changes are minimal, and some changes just affect where certain components of AFL are installed.

## Changes
* Introduce an overflow-byte, should increase the max size of the logarthmic hit count buckets used by AFL. For example, where vanilla AFL will only be interested in branch hit counts of 1, 2, 4, 8, ... up to 256, now our max is 65536.
* Install QEMU tracer into `<base_dir>/tracers/i386/afl-qemu-tracer`, this is to increase the flexibilty of the [Fuzzer](https://git.seclab.cs.ucsb.edu/cgc/fuzzer) project.
* Handle the reception of a SIGUSR1 signal, which QEMU will raise if it detects a raw leak of the flag page. QEMU will only raise this signal if it sees any 4 contiguous bytes in the flag page mirrored in a buffer being transmitted.
