# objectmanager.py
#
# Copyright (c) 2018, David Boddie <david@boddie.org.uk>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.

import sip
from PyQt5.QtCore import QCoreApplication, QObject, pyqtSignal
from PyQt5 import QtCore, QtGui, QtWidgets

class ObjectManager(QObject):

    messagePending = pyqtSignal(str)
    debugMessage = pyqtSignal(str)
    finished = pyqtSignal()
    
    NoReturnValue = object()
    
    def __init__(self, parent = None, debug = False):
    
        QObject.__init__(self, parent)
        self.debug = debug
        
        self.classes = {}
        
        for module in QtCore, QtCore.Qt, QtGui, QtWidgets:
            for name, obj in module.__dict__.items():
                try:
                    if issubclass(obj, QObject):
                        self.classes[name] = obj
                    elif issubclass(obj, sip.simplewrapper):
                        self.classes[name] = obj
                except TypeError:
                    pass
        
        self.objects = {}
        self.filters = {}
        self.names = {}
        self.pending_signals = {}
        self.pending_events = {}
        self.counter = 0
    
    def handleCommand(self, command):
    
        # create    <id> <name>   <type>   <args>...
        # forget    <id> <name>
        # call      <id> <flags>  <object> <method> <args>...
        # connect   <id> <src>    <signal>
        # rconnect  <id> <src>    <signal> <dest>   <slot>
        # filter    <id> <object> <event type>
        # process   <id>
        
        space = command.find(" ")
        if space == -1:
            return
        
        try:
            args, defs = self.parse_arguments(command)
        except ValueError as e:
            self.debugMessage.emit(str(e))
            return
        
        cmd = args.pop(0)
        id_ = args[0]
        flags = None
        
        try:
            if cmd == "create":
                result = self.create(args, defs)
            elif cmd == "forget":
                result = self.forget(args, defs)
            elif cmd == "call":
                result = self.call_method(args, defs)
                flags = args[1].split(",")
            elif cmd == "connect":
                result = self.connect(args, defs)
            elif cmd == "rconnect":
                result = self.remote_connect(args, defs)
            elif cmd == "filter":
                result = self.filter_object(args, defs)
            elif cmd == "process":
                result = self.process(args, defs)
            else:
                return
        
        except ValueError:
            self.debugMessage.emit("Invalid arguments for '%s' command: %s" % (
                                   cmd, repr(args)))
            return
        
        if result != self.NoReturnValue:
        
            # Send the return value of the method call.
            message = self.typed_value_to_string("value") + \
                self.typed_value_to_string(id_) + \
                self.typed_value_to_string(result, defs, flags)
            
            self.messagePending.emit(message)
    
    def create(self, args, defs):
    
        (id_, name, class_), method_args = args[:3], args[3:]
        
        try:
            obj = class_(*tuple(method_args))
            self.objects[name] = obj
            self.names[obj] = name
        except:
            pass
        
        return self.NoReturnValue
    
    def forget(self, args, defs):
    
        id_, name = args[:2]
        
        try:
            obj = self.objects[name]
            del self.objects[name]
            del self.names[obj]
            
            # If the object being deleted is an event then look up its queue
            # in the pending events dictionary.
            if name in self.pending_events:
            
                # Remove the first event object of this type from the set of
                # pending events.
                self.pending_events[name].pop(0)
                
                # Dispatch the next pending event for this object and type.
                self.dispatchEvent(name)
        except:
            pass
        
        return self.NoReturnValue
    
    def call_method(self, args, defs):
    
        (id_, flags, obj, method_name), method_args = args[:4], args[4:]
        
        if type(obj) == str:
            self.debugMessage.emit("Unknown object '%s'." % obj)
            return
        
        flags_chars = flags.split(",")
        keep_result = "k" in flags_chars
        
        try:
            # PyQt handles the method resolution but we could use signatures
            # instead of plain method names and look up the specific method
            # using QMetaObject.
            method = getattr(obj, method_name)
            value = method(*tuple(method_args))
            
            if keep_result:
                name = "%s_%i_rv" % (value.__class__.__name__, self.counter)
                self.objects[name] = value
                self.names[value] = name
                self.counter = (self.counter + 1) & 0xffffffff
                return name
            
            return value
        
        except AttributeError:
            self.debugMessage.emit("Object '%s' (%s) has no method '%s'." % (
                                   defs[obj], obj, method_name))
            return None
    
    def connect(self, args, defs):
    
        id_, src, signal_name = args[:3]
        
        try:
            signal = getattr(src, signal_name)
            
            # We could connect the signal to a newly created callable but this
            # might be difficult to reproduce if we wanted to reimplement this
            # in C++, so instead we create a receiver object to relay the
            # signal.
            receiver = SignalReceiver(id_, self)
            self.debugMessage.emit("Connecting %s.%s" % (defs[src], signal_name))
            signal.connect(receiver.dispatch)
        
        except AttributeError:
            self.debugMessage.emit("No such signal '%s.%s'." % (src.__class__.__name__, signal))
        
        return None
    
    def remote_connect(self, args, defs):
    
        id_, src, signal_name, dest, slot_name = args[:5]
        
        try:
            signal = getattr(src, signal_name)
        except AttributeError:
            self.debugMessage.emit("No such signal '%s.%s'." % (src.__class__.__name__, signal))
        
        try:
            slot = getattr(dest, slot_name)
        except AttributeError:
            self.debugMessage.emit("No such signal '%s.%s'." % (src.__class__.__name__, signal))
        
        # Connect the signal to a slot on this side of the bridge.
        signal.connect(slot)
        
        return None
    
    def filter_object(self, args, defs):
    
        id_, obj, event_type = args[:3]
        
        # Create a filter object for the object.
        filter_obj = FilterObject(id_, self)
        filter_obj.addEventType(event_type)
        obj.installEventFilter(filter_obj)
        
        return None
    
    def process(self, args, defs):
    
        id_ = args[0]
        
        # Indicate that the signal associated with an identifier has been
        # processed.
        try:
            pending = self.pending_signals[id_]
            pending.pop(0)
            self.dispatchSignal(id_)
        except KeyError:
            pass
        
        return self.NoReturnValue
    
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
            # Tuple
            args, tdefs = self.parse_arguments(arg)
            defs.update(tdefs)
            return tuple(args)
        
        elif type_ == "B":
            return {"True": True, "False": False}[arg]
        
        elif type_ == "N":
            return None
        
        elif type_ == "I" and arg in self.objects:
            # Instance
            obj = self.objects[arg]
            self.names[obj] = defs[obj] = arg
            return obj
        
        elif type_ == "C" and arg in self.classes:
            # Class
            class_ = self.classes[arg]
            defs[class_] = arg
            return class_
        
        elif type_ == "v":
            # Enum or value class and values
            args, tdefs = self.parse_arguments(arg)
            class_ = args[0]
            values = args[1:]
            return class_(*values)
        
        else:
            raise ValueError("Cannot decode value %s of type '%s'.\n" % (repr(arg), type_))
    
    type_to_str = {str: "s", int: "i", float: "f", bytes: "b"}
    
    def typed_value_to_string(self, value, defs = None, flags = None):
    
        type_ = type(value)
        
        if type_ in self.type_to_str:
            c = self.type_to_str[type_]
            s = str(value)
            return "%s%i %s " % (c, len(s), s)
        
        elif type_ == tuple:
            l = map(self.typed_value_to_string, list(value))
            s = "".join(l)
            return "t%i %s " % (len(s), s)
        
        elif flags and "v" in flags[0]:
            # Return a tuple containing primitive values unpacked from the
            # value as described by the flags string.
            names = flags[1:]
            l = []
            for name in names:
                l.append(getattr(value, name)())
            return self.typed_value_to_string(tuple(l))
        
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
        if not self.debug:
            self.finished.emit()
    
    def handleFinished(self):
    
        if not self.debug:
            self.finished.emit()
    
    def queueSignal(self, id_, args):
    
        serialised_args = []
        for arg in args:
            serialised_args.append(self.typed_value_to_string(arg, self.names))
        
        # Put this signal in a queue for the given identifier.
        pending = self.pending_signals.setdefault(id_, [])
        pending.append(serialised_args)
        
        # Try to dispatch the signal.
        self.dispatchSignal(id_)
    
    def dispatchSignal(self, id_):
    
        # If there is more than one queued signal then defer dispatch until later.
        pending = self.pending_signals[id_]
        if len(pending) != 1:
            return
        
        serialised_args = pending[0]
        
        message = self.typed_value_to_string("signal") + \
            self.typed_value_to_string(id_) + \
            "".join(serialised_args)
        
        self.messagePending.emit(message)
    
    def queueEvent(self, id_, event):
    
        etype = int(event.type())
        name = "event_%i_%i" % (id_, etype)
        
        # Put this event in a queue.
        pending = self.pending_events.setdefault(name, [])
        pending.append((id_, event))
        
        # Try to dispatch the event.
        self.dispatchEvent(name)
    
    def dispatchEvent(self, event_obj_name):
    
        # If there is more than one queued event for this target object and
        # type then defer dispatch until later.
        pending = self.pending_events[event_obj_name]
        if len(pending) != 1:
            return
        
        id_, event = pending[0]
        
        # Store the event in the object dictionary using a name derived from
        # the source object and the event type. This should yield a unique name
        # until the next time the same type of event is dispatched for the
        # same object.
        self.objects[event_obj_name] = event
        self.names[event] = event_obj_name
        
        # Send a message with id = 1 to indicate that it is an event.
        message = self.typed_value_to_string("event") + \
            self.typed_value_to_string(id_) + \
            self.typed_value_to_string(event, self.names)
        
        self.messagePending.emit(message)


class SignalReceiver(QObject):

    def __init__(self, id_, objectManager):
    
        QObject.__init__(self, objectManager)
        
        self.id_ = id_
        self.objectManager = objectManager
    
    def dispatch(self, *args):
    
        self.objectManager.queueSignal(self.id_, args)


class FilterObject(QObject):

    def __init__(self, id_, objectManager):
    
        QObject.__init__(self, objectManager)
        
        self.id_ = id_
        self.events = set()
        self.objectManager = objectManager
    
    def eventFilter(self, obj, event):
    
        if int(event.type()) in self.events:
        
            # For some events to be useful, we need to create copies of them
            # to prevent taking a reference to a data structure that will be
            # modified and invalidated. Perhaps it isn't useful to transmit
            # the event object itself, only the event type.
            if event.type() == QtCore.QEvent.Resize:
                event = QtGui.QResizeEvent(event.size(), event.oldSize());
            
            self.objectManager.queueEvent(self.id_, event)
            return True
        
        return False
    
    def addEventType(self, event_type):
    
        self.events.add(event_type)
