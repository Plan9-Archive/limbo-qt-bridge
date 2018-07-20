from PyQt5.QtCore import QCoreApplication, QObject
from PyQt5 import QtWidgets

class ObjectManager(QObject):

    classes = {
        "QWidget": QtWidgets.QWidget
        }
    
    def __init__(self, parent = None):
    
        QObject.__init__(self, parent)
        
        self.objects = {}
    
    def handleCommand(self, command):
    
        space = command.find(" ")
        if space == -1:
            return
        
        cmd, args = command[:space].rstrip(), command[space + 1:]
        
        try:
            if cmd == "create":
                self.create(args)
            elif cmd == "call":
                self.call_method(args)
        
        except ValueError:
            print("Invalid arguments for '%s' command: %s" % (cmd, args))
            return
    
    def create(self, args):
    
        try:
            class_name, name = self.parse_arguments(args)[:2]
            class_ = self.classes[class_name]
        except KeyError:
            print("Unknown class '%s'." % class_name)
            return
        
        obj = class_()
        self.objects[name] = obj
    
    def call_method(self, args):
    
        args = self.parse_arguments(args)
        (name, method), method_args = args[:2], args[2:]
        try:
            obj = self.objects[name]
            # PyQt handles the method resolution but we could use signatures
            # instead of plain method names and look up the specific method
            # using QMetaObject.
            method = getattr(obj, method)
            method(*tuple(method_args))
        except KeyError:
            print("Unknown object '%s'." % name)
        except AttributeError:
            print("Object '%s' has no method '%s'." % (name, method))
    
    def parse_arguments(self, text):
    
        args = []
        in_quote = False
        arg = ""
        n = 0
        
        for c in text:
            if c == " ":
                if in_quote:
                    arg += c
                elif arg != "":
                    args.append(arg)
                    arg = ""
            elif c == '"':
                if in_quote:
                    arg += c
                    in_quote = False
                elif arg != "":
                    raise ValueError("Unexpected quote at column %i in '%s'." % (n, text))
                else:
                    arg += c
                    in_quote = True
            else:
                arg += c
            
            n += 1
        
        if arg != "":
            args.append(arg)
        
        return args
    
    def handleError(self):
    
        QtWidgets.QMessageBox.critical(None, "Qt Bridge",
            "The application quit unexpectedly.")
        QCoreApplication.instance().quit()
    
    def handleFinished(self):
    
        QCoreApplication.instance().quit()
