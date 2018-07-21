#!/usr/bin/env python3

import sys, time

def send(message):
    sys.stdout.write(message + "\n")
    sys.stdout.flush()

def receive(expecting):
    while True:
        line = sys.stdin.readline()
        if line.startswith(expecting):
            return line[len(expecting):].strip()

def call(message):
    send("call 3 " + message)
    return receive("value 3 ")


if __name__ == "__main__":

    send("create QLabel label")
    send('call 1 label setText "Hello World!"')
    send("call 2 label show")
    
    width = int(call("label width"))
    height = int(call("label height"))
    
    time.sleep(2)
    
    send("call 4 label resize %i %i" % (width * 2, height * 4))
    
    time.sleep(2)
    
    send("call 5 label close")
