from PyQt5.QtCore import QCoreApplication, QObject, pyqtSignal
from PyQt5 import QtWidgets

class ObjectManager(QObject):

    messagePending = pyqtSignal(str)
    debugMessage = pyqtSignal(str)
    
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
        self.counter = 0
    
    def handleCommand(self, command):
    
        space = command.find(" ")
        if space == -1:
            return
        
        cmd, args = command[:space].rstrip(), command[space + 1:]
        args, defs = self.parse_arguments(args)
        id_ = args[0]
        
        try:
            if cmd == "create":
                result = self.create(args, defs)
            elif cmd == "call":
                result = self.call_method(args, defs)
            elif cmd == "call_keep":
                result = self.call_method(args, defs, keep_result = True)
            else:
                return
        
        except ValueError:
            self.debugMessage.emit("Invalid arguments for '%s' command: %s" % (
                                   cmd, repr(args)))
            return
        
        # Send the return value of the method call.
        self.messagePending.emit("value %i %s\n" % (
            id_, self.typed_value_to_string(result)))
        self.debugMessage.emit("value %i %s\n" % (
            id_, self.typed_value_to_string(result)))
    
    def create(self, args, defs):
    
        # create <id> <type> <name>
        try:
            (id_, name, class_), method_args = args[:3], args[3:]
        
        except KeyError:
            self.debugMessage.emit("Unknown class '%s'." % class_name)
            return
        
        try:
            obj = class_(*tuple(method_args))
            self.objects[name] = obj
            return name
        except:
            return None
    
    def call_method(self, args, defs, keep_result = False):
    
        # call <id> <object> <method> <args>...
        (id_, obj, method_name), method_args = args[:3], args[3:]
        
        if type(obj) == str:
            self.debugMessage.emit("Unknown object '%s'." % obj)
            return
        
        try:
            # PyQt handles the method resolution but we could use signatures
            # instead of plain method names and look up the specific method
            # using QMetaObject.
            method = getattr(obj, method_name)
            value = method(*tuple(method_args))
            
            if keep_result:
                name = "%s_%i_rv" % (value.__class__.__name__, self.counter)
                self.objects[name] = value
                self.counter = (self.counter + 1) & 0xffffffff
                return name
            
            return value
        
        except AttributeError:
            self.debugMessage.emit("Object '%s' (%s) has no method '%s'." % (
                                   defs[obj], obj, method_name))
            return None
    
    def parse_arguments(self, text):
    
        # Create an empty list to fill with arguments and a dictionary mapping
        # classes and objects to their original names in the argument text.
        args = []
        defs = {}
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
                    args.append(self.string_to_typed_value(arg, defs))
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
            raise ValueError("Unmatched quotes at end of '%s'." % text)
        
        if arg != "":
            args.append(self.string_to_typed_value(arg, defs))
        
        return args, defs
    
    def string_to_typed_value(self, arg, defs):
    
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
            obj = self.objects[arg]
            defs[obj] = arg
            return obj
        
        elif arg in self.classes:
            class_ = self.classes[arg]
            defs[class_] = arg
            return class_
        
        # Just return a string.
        return arg
    
    def typed_value_to_string(self, value):
    
        return str(value)
    
    def handleError(self, message):
    
        QtWidgets.QMessageBox.critical(None, "Qt Bridge", message)
        QCoreApplication.instance().quit()
    
    def handleFinished(self):
    
        QCoreApplication.instance().quit()
