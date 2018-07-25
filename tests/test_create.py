#!/usr/bin/env python3

import sys, time

def send(message):
    sys.stdout.write("%i %s" % (len(message), message))
    sys.stdout.flush()

def enc(value, type_):
    s = str(value)
    return "%s%i %s" % (type_, len(s), s)

def create(id_, name, class_):
    send("%s %s %s %s\n" % (enc("create", "s"), enc(id_, "i"), enc(name, "s"), enc(class_, "C")))

def call(id_, obj, method):
    send("%s %s %s %s\n" % (enc("call", "s"), enc(id_, "i"), enc(obj, "I"), enc(method, "s")))

if __name__ == "__main__":

    create(1, "window", "QWidget")
    call(2, "window", "show")
    
    time.sleep(3)
    
    call(3, "window", "close")
    
    time.sleep(1)
