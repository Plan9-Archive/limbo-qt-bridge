#!/usr/bin/env python3

import sys, time

def send(message):
    sys.stdout.write(message + "\n")
    sys.stdout.flush()

if __name__ == "__main__":

    send("create 0 label QLabel")
    send('call 1 label setText "Counting"')
    send("call 2 label show")
    
    i = 5
    while i > 0:
        send('call 3 label setText "%i"' % i)
        i -= 1
        time.sleep(1)
    
    send("call 4 label close")
    
    time.sleep(1)
