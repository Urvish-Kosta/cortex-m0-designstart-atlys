#!/usr/bin/env python3
"""bin2hex.py -- convert a raw firmware .bin into the hex format loaded by
rtl/soc/ahb_mem.vhd: one 32-bit word per line, uppercase hex, little-endian
byte order within each word (matching the Cortex-M0's view of memory).

Usage: bin2hex.py input.bin output.hex

Author: Urvish Kosta
License: MIT (see LICENSE at repository root)
"""
import sys
import struct


def main() -> int:
    if len(sys.argv) != 3:
        print(__doc__)
        return 1

    src, dst = sys.argv[1], sys.argv[2]

    with open(src, "rb") as f:
        data = f.read()

    # Pad to a multiple of 4 bytes.
    if len(data) % 4:
        data += b"\x00" * (4 - len(data) % 4)

    with open(dst, "w") as f:
        for i in range(0, len(data), 4):
            (word,) = struct.unpack_from("<I", data, i)
            f.write(f"{word:08X}\n")

    print(f"{dst}: {len(data)//4} words ({len(data)} bytes)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
