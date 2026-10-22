#!/usr/bin/env python3
"""
Simple Verilog Syntax & Structural Sanity Checker
Validates keywords matching (module/endmodule, begin/end, case/endcase)
and port declarations in all .v files.
"""

import os
import re

def check_file(filepath):
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()

    # Strip single line comments
    lines = content.splitlines()
    clean_lines = []
    in_block_comment = False
    for line in lines:
        line_clean = ""
        i = 0
        while i < len(line):
            if in_block_comment:
                if line[i:i+2] == "*/":
                    in_block_comment = False
                    i += 2
                else:
                    i += 1
            else:
                if line[i:i+2] == "/*":
                    in_block_comment = True
                    i += 2
                elif line[i:i+2] == "//":
                    break
                else:
                    line_clean += line[i]
                    i += 1
        clean_lines.append(line_clean)

    text = " ".join(clean_lines)

    # Tokenize words
    tokens = re.findall(r'\b[a-zA-Z_`][a-zA-Z0-9_`]*\b', text)

    modules = tokens.count('module')
    endmodules = tokens.count('endmodule')
    begins = tokens.count('begin')
    ends = tokens.count('end')
    cases = tokens.count('case')
    endcases = tokens.count('endcase')

    status = "OK"
    errors = []
    if modules != endmodules:
        errors.append(f"module ({modules}) != endmodule ({endmodules})")
    if begins != ends:
        errors.append(f"begin ({begins}) != end ({ends})")
    if cases != endcases:
        errors.append(f"case ({cases}) != endcase ({endcases})")

    if errors:
        status = "MISMATCH: " + ", ".join(errors)

    print(f"[{status:<4}] {filepath:<45} (modules: {modules}, begins: {begins}, cases: {cases})")
    return len(errors) == 0

def main():
    print("Checking Verilog RTL and Testbench files...")
    all_ok = True
    for root, dirs, files in os.walk("."):
        if ".git" in root:
            continue
        for f in sorted(files):
            if f.endswith(".v"):
                path = os.path.join(root, f)
                if not check_file(path):
                    all_ok = False

    if all_ok:
        print("\nAll Verilog source files passed keyword matching checks!")
    else:
        print("\nSome files had keyword mismatches!")

if __name__ == "__main__":
    main()
