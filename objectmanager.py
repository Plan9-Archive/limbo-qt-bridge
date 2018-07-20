from PyQt5.QtCore import QCoreApplication, QObject
from PyQt5 import QtWidgets

class ObjectManager(QObject):

    def __init__(self, parent = None):
    
        QObject.__init__(self, parent)
        
        self.classes = {}
        for name, obj in QtWidgets.__dict__.items():
            try:
                if issubclass(obj, QObject):
                    self.classes[name] = obj
            except TypeError:
                pass
        
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
            class_, name = self.parse_arguments(args)[:2]
        except KeyError:
            print("Unknown class '%s'." % class_name)
            return
        
        obj = class_()
        self.objects[name] = obj
    
    def call_method(self, args):
    
        args = self.parse_arguments(args)
        (obj, method), method_args = args[:2], args[2:]
        
        if type(obj) == str:
            print("Unknown object '%s'." % obj)
            return
        
        try:
            # PyQt handles the method resolution but we could use signatures
            # instead of plain method names and look up the specific method
            # using QMetaObject.
            method = getattr(obj, method)
            method(*tuple(method_args))
        except AttributeError:
            print("Object %s has no method '%s'." % (obj, method))
    
    def parse_arguments(self, text):
    
        args = []
        in_quote = False
        arg = ""
        n = 0
        
        for c in text:
            if c == " ":
                if in_quote:
                    # Spaces are included verbatim in quotes...
                    arg += c
                elif arg != "":
                    # ...or are separators between arguments.
                    args.append(self.string_to_type(arg))
                    arg = ""
            
            elif c == '"':
                if in_quote:
                    # Closing quotes are included verbatim.
                    arg += c
                    in_quote = False
                elif arg != "":
                    # An opening quote must be the first character.
                    raise ValueError("Unexpected quote at column %i in '%s'." % (n, text))
                else:
                    # Opening quotes are included verbatim.
                    arg += c
                    in_quote = True
            
            elif not in_quote and arg[-1:] == '"':
                # Other characters cannot follow closing quotes.
                raise ValueError("Unexpected character following quote at column %i in '%s'." % (n, text))
            else:
                # Include all other characters.
                arg += c
            
            n += 1
        
        if in_quote:
            raise ValueError("Unmatches quotes at end of '%s'." % text)
        
        if arg != "":
            args.append(self.string_to_type(arg))
        
        return args
    
    def string_to_type(self, arg):
    
        # Check for data of various types.
        
        if arg.startswith('"'):
            # Already a string so just remove the quotes.
            return arg[1:-1]
        
        # A boolean or None value?
        try:
            return {"True": True, "False": False, "None": None}[arg]
        except KeyError:
            pass
        
        # A floating point value?
        if "." in arg:
            try:
                return float(arg)
            except ValueError:
                pass
        
        # An integer?
        try:
            if arg.startswith("0x"):
                return int(arg, 16)
            else:
                return int(arg)
        except ValueError:
            pass
        
        # The name of an object or class?
        if arg in self.objects:
            return self.objects[arg]
        elif arg in self.classes:
            return self.classes[arg]
        
        # Just return a string.
        return arg
    
    def handleError(self):
    
        QtWidgets.QMessageBox.critical(None, "Qt Bridge",
            "The application quit unexpectedly.")
        QCoreApplication.instance().quit()
    
    def handleFinished(self):
    
        QCoreApplication.instance().quit()
