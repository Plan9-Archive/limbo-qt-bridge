#!/usr/bin/env python3

import sys, time

def send(message):
    sys.stdout.write("%i %s\n" % (len(message), message))
    sys.stdout.flush()

def receive(expecting):
    in_message = False
    current = ""
    length = 0
    
    while True:
        current += sys.stdin.read(1)
        
        if not in_message:
            space = current.find(" ")
            if space == -1:
                continue
            
            length = int(current[:space])
            current = current[space + 1:]
            in_message = True
        
        if len(current) > length:
        
            content = current[:length]
            
            if content.startswith(expecting):
                return content
            
            current = current[length + 1:]
            in_message = False

def call(message):
    send("call 3 " + message)
    result = receive("value 3 ")
    return result.split(" ")[-1]


if __name__ == "__main__":

    send("create 0 label QLabel")
    send('call 1 label setText "Hello \\"World\\"!"')
    send("call 2 label show")
    
    width = int(call("label width"))
    height = int(call("label height"))
    
    time.sleep(2)
    
    send("call 4 label resize %i %i" % (width * 2, height * 4))
    
    time.sleep(2)
    
    send("call 5 label close")
