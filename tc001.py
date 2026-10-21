#!/usr/bin/env python3
"""Make the TC001's copies of the scripts: Clock.tc001.be and Weather.tc001.be.

    python3 tc001.py

A TC001 shares 96 KB among its scripts, and a script compiles only into memory in one piece as
large as its source, which an encrypted connection of another script, as Netatmo's, cuts up. So
the copies leave out what the clock does not need: comments, indentation, the settings' help
texts and the header's spaces, and string literals side by side are joined into one.
Only the Python standard library.
"""
import re


def compact(source):
    out = []
    for line in source.split("\n"):
        if line.startswith("# @"):
            line = re.sub(r' help="[^"]*"', "", line)
            out.append(re.sub(r" {2,}", " ", line))
            continue
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith('"') and out and out[-1].endswith('"') and not out[-1].endswith('",'):
            out[-1] = out[-1][:-1] + line[1:]           # literals side by side are one string
            continue
        out.append(line)
    return "\n".join(out) + "\n"


if __name__ == "__main__":
    for name in ("Clock", "Weather"):
        source = open(name + ".be", encoding="utf-8").read()
        text = compact(source)
        open(name + ".tc001.be", "w", encoding="utf-8").write(text)
        print(f"{name}.tc001.be: {len(text.encode())} bytes, from {len(source.encode())}")
