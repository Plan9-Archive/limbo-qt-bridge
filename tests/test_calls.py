#!/usr/bin/env python3

import sys, time

def send(message):
    sys.stdout.write(message + "\n")
    sys.stdout.flush()

if __name__ == "__main__":

    send("create QLabel label")
    send('call label setText "Counting"')
    send("call label show")
    
    i = 10
    while i > 0:
        send('call label setText "%i"' % i)
        i -= 1
        time.sleep(1)
    
    send("call label close")
    
    time.sleep(1)
