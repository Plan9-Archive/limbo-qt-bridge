Limbo to Qt Bridge
==================

The Qt API is exposed via a PyQt program that runs the Limbo program as a
subprocess. The Limbo program accesses the API by writing messages to its
stdout channel and receives messages containing return values via its stdin
channel. Signals emitted by Qt objects are also reported to the Limbo program
when appropriate via its stdin channel.

Qt classes are represented in Limbo by ADTs. Instances of these classes are
typically created by calling the new() function of the corresponding ADT,
unless the instance is created as the result of an API call. Each instance of
a Qt class is referred to within each ADT instance by a proxy which contains
the name of the instance on the other side of the bridge.

ADTs representing classes whose instances can be supplied as arguments to
methods need to provide the _get_proxy() function so that their proxies can be
obtained and sent across the bridge. This interface is our way of indicating
that an ADT instance represents a Qt object.


Message format
--------------

Messages are sequences of bytes in which strings are encoded using UTF-8.
Each message begins with a series of characters indicating the length of the
message body, followed by a single space.

    <message> := "<length> <message body>"

The message body is a sequence of values, each of which is encoded in the
following format:

    <value> := "<typecode><length> <value> "

The typecode specifies the type that the decoded value should have. The length
is the number of bytes in the encoded value string. The typecode-length and the
encoded value are separated by a space, and the value is followed by a space or
newline.

Examples of encoded types include the following:

    i = integer
    <integer value> := "i<length> <value> "
    Example: "i3 123 "

    f = float
    <float value> := "f<length> <value> "
    Example: "f4 1.23 "

    s = string
    <string value> := "s<length> <value> "
    Example: "s5 Hello "

    b = bytes
    <bytes value> := "b<length> <value> "
    Example: "b10 xxxxxXXXXX "

    T = True
    <True value> := "T4 True "

    F = False
    <False value> := "F5 False "

    N = None
    <None value> := "N4 None "

    I = instance
    <instance> := "I<length> <name> "
    Example: "I9 QWidget_0 "

    C = class
    <instance> := "C<length> <name> "
    Example: "C7 QWidget "

    t = tuple
    <tuple> := "t<length> <value>... "
    Example: "t24 s5 Hello s5 World i1 7  "

    v = enum or value class and values
    <enum value> := "v<length> C<length> <name> i<length> <value>  "
    Example: "v18 C9 Alignment i1 1  "
    <value class instance> := "v<length> C<length> <name> <value>... "
    Example: "v23 C6 QPoint i3 123 i2 96  "

Note that encoded values of types that contain values, such as tuples, enum
values and value class instances tend to end in double spaces for ease and
consistency of implementation.

The sequence of values in a message body follows the following convention:

    <message body> := "<command> <id> <argument>..."

The arguments used depend on the command. The identifier sent with each
message is used to identify the corresponding response message. Identifiers for
regular requests and responses are allocated from a different range of integers
to those used for signals and events because the latter are persistent.


Message types
-------------

An object is created in the PyQt environment by sending a `create` message:

    <create message> := "create <id> <name> <type> <argument>..."
    Example: "create 4 QWidget_2 QWidget"
    Encoded: "s6 create i1 4 s9 QWidget_2 s7 QWidget "

The name given is used to refer to the object in other messages. For example,
it is used in the `call` message to call its methods.

No message is sent in response to a message of this type.

When an object is no longer needed it can be allowed to go out of scope. Since
many objects are used for the duration of the application's lifetime, they
don't need to be deleted in the PyQt environment. For those that do need to be
tidied up, the `forget` message is used:

    <forget message> := "forget <id> <name> "
    Example: "forget 16 QWidget_2"
    Encoded: "s6 forget i2 16 s9 QWidget_2 "

PyQt will ensure that the object is deleted if necessary, or transfer ownership
to Qt. It's entry will be deleted from the dictionary that maps names of
objects visible to Limbo to Qt objects.

No message is sent in response to a message of this type.

Calling a method of an object is achieved by sending the `call` message:

    <call message> := "call <id> <flags> <object> <method> <args>..."
    Example: "call QWidget_2 setWindowTitle 'My Window'"
    Encoded: "s4 call i2 11 s0 I9 QWidget_2 s14 setWindowTitle s9 My Window "

Note that the flags string is empty in this case, so it is encoded as "s0 ".
The flags are used to control how return values are handled. In cases where an
object is returned that the caller will need to refer to, the "k" flag ensures
that the return value is registered in the same way as an object created with
the `create` message, only with an auto-generated name based on the type of
object returned:

    Example:  "call 3 'k' QMainWindow_0 s7 menuBar"
    Encoded:  "s4 call i1 3 s1 k I13 QMainWindow_0 s7 menuBar "
    Response: "s5 value i1 3 s13 QMenuBar_1_rv "
    Decoded:  "value 3 QMenuBar_1_rv"

Some calls return instances of "value" classes that represent interchangeable
values, such as sizes, points and rectangles. Although the caller would need to
access the methods on these values themselves, it would be wasteful to keep
these objects for future reference, and it would require the caller to manually
dispose of them using the `forget` message. To solve this problem, we use the
"v" flag to cause the value's to be unpacked into a sequence of simpler values.

For example, a `QPixmap` instance has a `size` method that returns a `QSize`
instance containing width and height information. These dimensions are obtained
using the `width` and `height` methods of the `QSize` instance. Since we do not
wish to manage this intermediate object, the `size` method can be called using
the `call` message with "v,width,height" indicating that the `width` and
`height` methods of the `QSize` instance should be called and their values
returned in a tuple instead:

    Example:  "call 8 v,width,height QPixmap_1 size"
    Encoded:  "s4 call i1 8 s14 v,width,height I9 QPixmap_1 s4 size "
    Response: "s5 value i1 8 t14 i3 100 i3 100 "
    Decoded:  "value 8 (100 100)"

Signal-slot connections are created using either of the `connect` or `rconnect`
messages. The `connect` message connects a signal from a Qt object to a slot
written in Limbo:

    <connect message> := "connect <id> <src> <signal>"
    Example: "connect 1025 QAction_3_rv triggered "
    Encoded: "s7 connect i4 1025 I12 QAction_3_rv s9 triggered "

Note that the identifier used to tag the message will be used for messages that
report signal emission, such as the following:

    <signal message> := "signal <id> <value>"
    Response: "s6 signal i4 1025 B5 False "
    Decoded:  "signal 1025 False"

The identifier is allocated from a range that is separate from the usual range
of identifiers used for regular messages.

In order to avoid deadlocks, the PyQt environment queues signals from the same
connection and only delivers one at a time. After a `signal` message has been
sent, the environment waits for a `process` message to remove the signal from
the queue and send the next one, if present:

    <process message> := "process <id>"
    Example: "process 1025"
    Encoded: "s7 process i4 1025 "

No message is sent in response to a message of this type.

The `rconnect` message connects a signal from a Qt object to a slot in another
Qt object entirely within the PyQt environment:

    <rconnect message> := "rconnect <id> <src> <signal> <dest> <slot>"
    Example: "rconnect 29 QPushButton_e clicked QDialog_0 accept"
    Encoded: "s8 rconnect i2 29 I13 QPushButton_e s7 clicked I9 QDialog_0 s6 accept "

No notification messages will be sent across the bridge for connections like
this.

Since there is no way to subclass widgets, it can be useful to apply event
filters to objects in order to receive some of the events they receive. This is
achieved by sending a `filter` message for a given object and event type, as in
this example which filters resize events sent to a label widget:

    <filter message> := "filter <id> <object> <event type>"
    Example: "filter 1025 QLabel_0 14 "
    Encoded: "s6 filter i4 1025 I8 QLabel_0 i2 14 "

The identifier used to tag the message is used for messages that report events,
such as the following:

    <event message> := ""
    Response: "s5 event i4 1025 I13 event_1025_14 "
    Decoded:  "event 1025 event_1025_14"

The identifier is allocated from the same range of identifiers that signal
connections use because, as with connections, filters tend to be permanently
installed on objects.

Each event causes an event object to be registered with the PyQt environment.
As with signals, we need a mechanism to avoid deadlocks that can occur if an
event handler is called while it is already being executed. Where signals are
kept moving in the queue by the use of the `process` message, we instead
indicate that an event has been handled by sending a `forget` message, as in
the following example:

    Example: "forget 8 event_1025_14"
    Encoded: "s6 forget i1 8 s13 event_1025_14 "

This causes the next pending event to be sent for the given object and event
type.
