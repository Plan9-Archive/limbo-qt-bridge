#!/usr/bin/env python3

import sys, time

def send(message):
    sys.stdout.write("%i %s\n" % (len(message), message))
    sys.stdout.flush()

if __name__ == "__main__":

    send("create 1 window QWidget")
    send("call 2 window show")
    
    time.sleep(3)
    
    send("call 3 window close")
    
    time.sleep(1)
