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

type_to_str = {str: "s", int: "i"}

def call(id_, obj, method, *args):
    a = []
    for arg in args:
        c = type_to_str[type(arg)]
        a.append(enc(arg, c))
    
    send("%s %s %s %s %s\n" % (enc("call", "s"), enc(id_, "i"), enc(obj, "I"),
        enc(method, "s"), " ".join(a)))

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
        
        if len(current) >= length:
        
            content = current[:length]
            args = parse(content)
            
            if tuple(args[:2]) == expecting:
                return args[2:]
            
            current = current[length:]
            in_message = False

str_to_type = {"i": int, "s": str}

def parse(text):

    args = []
    i = 0
    while i < len(text):
        type_ = text[i]
        space = text.find(" ", i)
        length = int(text[i + 1:space])
        value = text[space + 1:space + 1 + length]
        if type_ in str_to_type:
            value = str_to_type[type_](value)
        elif type_ == "N":
            value = None
        args.append(value)
        i = space + 1 + length + 1
    
    return args

def call_receive(id_, obj, method, *args):
    call(id_, obj, method, *args)
    return receive(("value", 3))


if __name__ == "__main__":

    create(0, "label", "QLabel")
    call(1, "label", "setText", 'Hello "World"!')
    call(2, "label", "show")
    
    width = int(call_receive(3, "label", "width")[0])
    height = int(call_receive(3, "label", "height")[0])
    
    time.sleep(2)
    
    call(4, "label", "resize", width * 2, height * 4)
    
    time.sleep(2)
    
    call(5, "label", "close")
