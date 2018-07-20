#!/usr/bin/env python3

import sys, time

if __name__ == "__main__":

    sys.stdout.write("create QWidget window\n")
    sys.stdout.flush()
    
    sys.stdout.write("call window show\n")
    sys.stdout.flush()
    
    time.sleep(3)
    
    sys.stdout.write("call window close\n")
    sys.stdout.flush()
    
    time.sleep(1)
