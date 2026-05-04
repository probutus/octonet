#!/usr/bin/env python2.7

import os
import sys
import py_compile

def compile_recursive(root):
    for dirpath, dirnames, filenames in os.walk(root):
        for filename in filenames:
            if filename.endswith('.py'):
                path = os.path.join(dirpath, filename)
                try:
                    py_compile.compile(path, doraise=True)
                except Exception as e:
                    print("Error compiling %s: %s" % (path, e))

if __name__ == '__main__':
    if len(sys.argv) < 2:
        sys.exit(1)
    for root in sys.argv[1:]:
        compile_recursive(root)

