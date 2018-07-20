#!/usr/bin/env python3

import sys, time

def send(message):
    sys.stdout.write(message + "\n")
    sys.stdout.flush()

if __name__ == "__main__":

    send("create QWidget window")
    send("call window show")
    
    time.sleep(3)
    
    send("call window close")
    
    time.sleep(1)
