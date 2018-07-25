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

def call(id_, obj, method, *args):
    a = []
    for arg in args:
        a.append(enc(arg, "s"))
    
    send("%s %s %s %s %s\n" % (enc("call", "s"), enc(id_, "i"), enc(obj, "I"),
        enc(method, "s"), " ".join(a)))

if __name__ == "__main__":

    create(0, "label", "QLabel")
    call(1, "label", "setText", "Counting")
    call(2, "label", "show")
    
    i = 5
    while i > 0:
        call(3, "label", "setText", "%i" % i)
        i -= 1
        time.sleep(1)
    
    call(4, "label", "close")
    
    time.sleep(1)
