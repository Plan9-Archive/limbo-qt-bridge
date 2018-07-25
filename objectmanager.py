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
    
        # create    <id> <name>   <type>   <args>...
        # forget    <id> <name>
        # call      <id> <object> <method> <args>...
        # call_keep <id> <object> <method> <args>...
        # connect   <id> <src>    <signal>
        
        space = command.find(" ")
        if space == -1:
            return
        
        args, defs = self.parse_arguments(command)
        cmd = args.pop(0)
        id_ = args[0]
        
        try:
            if cmd == "create":
                result = self.create(args, defs)
            elif cmd == "create":
                result = self.forget(args, defs)
            elif cmd == "call":
                result = self.call_method(args, defs)
            elif cmd == "call_keep":
                result = self.call_method(args, defs, keep_result = True)
            elif cmd == "connect":
                result = self.connect(args, defs)
            else:
                return
        
        except ValueError:
            self.debugMessage.emit("Invalid arguments for '%s' command: %s" % (
                                   cmd, repr(args)))
            return
        
        # Send the return value of the method call.
        self.messagePending.emit(
            self.typed_value_to_string("value") + \
            self.typed_value_to_string(id_) + \
            self.typed_value_to_string(result, defs))
        self.debugMessage.emit(
            self.typed_value_to_string("value") + \
            self.typed_value_to_string(id_) + \
            self.typed_value_to_string(result, defs))
    
    def create(self, args, defs):
    
        (id_, name, class_), method_args = args[:3], args[3:]
        
        try:
            obj = class_(*tuple(method_args))
            self.objects[name] = obj
            return name
        except:
            return None
    
    def forget(self, args, defs):
    
        id_, name = args[:2]
        
        try:
            del self.objects[name]
        except:
            return None
    
    def call_method(self, args, defs, keep_result = False):
    
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
    
    def connect(self, args, defs):
    
        id_, src, signal_name = args[:5]
        
        try:
            signal = getattr(src, signal_name)
            
            # We could connect the signal to a newly created callable but this
            # might be difficult to reproduce if we wanted to reimplement this
            # in C++, so instead we create a receiver object to relay the
            # signal.
            receiver = SignalReceiver(defs[src], signal_name, self)
            self.debugMessage.emit("Connecting %s.%s" % (defs[src], signal_name))
            signal.connect(receiver.dispatch)
        
        except AttributeError:
            self.debugMessage.emit("No such signal '%s.%s'." % (src.__class__.__name__, signal))
        
        return None
    
    def parse_arguments(self, text):
    
        # Create an empty list to fill with arguments and a dictionary mapping
        # classes and objects to their original names in the argument text.
        args = []
        defs = {}
        section = 0
        type_ = None
        length = 0
        arg = ""
        n = 0
        
        for c in text:
        
            if section == 0:
                # Read the type.
                type_ = c
                section = 1
                arg = ""
            
            elif section == 1:
                # Read the length:
                if c != " ":
                    arg += c
                else:
                    length = int(arg)
                    section = 2
                    arg = ""
            
            elif section == 2:
                # Read the value.
                if len(arg) < length:
                    arg += c
                else:
                    # Skip a character.
                    args.append(self.string_to_typed_value(arg, type_, defs))
                    section = 0
                    arg = ""
            
            n += 1
        
        return args, defs
    
    str_to_type = {"s": str, "i": int, "f": float, "b": bytes}
    
    def string_to_typed_value(self, arg, type_, defs):
    
        # Check for data of various types.
        if type_ in self.str_to_type:
            return self.str_to_type[type_](arg)
        
        elif type_ == "t":
            args, tdefs = self.parse_arguments(arg)
            defs.update(tdefs)
            return tuple(args)
        
        elif type_ == "B":
            return {"True": True, "False": False}[arg]
        
        elif type_ == "N":
            return None
        
        elif type_ == "I" and arg in self.objects:
            obj = self.objects[arg]
            defs[obj] = arg
            return obj
        
        elif type_ == "C" and arg in self.classes:
            class_ = self.classes[arg]
            defs[class_] = arg
            return class_
        
        else:
            raise ValueError("Cannot decode value %s of type '%s'.\n" % (repr(arg), type_))
    
    type_to_str = {str: "s", int: "i", float: "f", bytes: "b"}
    
    def typed_value_to_string(self, value, defs = None):
    
        type_ = type(value)
        
        if type_ in self.type_to_str:
            c = self.type_to_str[type_]
            s = str(value)
            return "%s%i %s " % (c, len(s), s)
        
        elif type_ == tuple:
            l = map(self.typed_value_to_string, list(value))
            s = "".join(l)
            return "t%i %s " % (len(s), s)
        
        elif defs and value in defs:
            s = defs[value]
            return "I%i %s " % (len(s), s)
        
        elif value == None:
            return "N4 None "
        elif value == True:
            return "B4 True "
        elif value == False:
            return "B5 False "
        else:
            raise ValueError("Cannot encode value %s.\n" % repr(value))
    
    def handleError(self, message):
    
        QtWidgets.QMessageBox.critical(None, "Qt Bridge", message)
        QCoreApplication.instance().quit()
    
    def handleFinished(self):
    
        #QCoreApplication.instance().quit()
        pass
    
    def dispatchSignal(self, src_name, signal_name, args):
    
        # Find the name of the sender.
        serialised_args = map(self.typed_value_to_string, args)
        self.messagePending.emit("signal 0 %s %s" % (src_name, signal_name) + \
            " " + " ".join(serialised_args))


class SignalReceiver(QObject):

    def __init__(self, src_name, signal_name, objectManager):
    
        QObject.__init__(self, objectManager)
        
        self.src_name = src_name
        self.signal = signal_name
        self.objectManager = objectManager
    
    def dispatch(self, *args):
    
        self.objectManager.dispatchSignal(self.src_name, self.signal, args)
