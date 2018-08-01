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

The arguments used depend on the command.


Accessing objects
-----------------

An object is created in the PyQt environment by sending a `create` message:

    <create message> := "create <id> <name> <type> <argument>..."
    Example: "create 4 QWidget_2 QWidget"
    Encoded: "s6 create i1 4 s9 QWidget_2 s7 QWidget "


Installing the modules
----------------------

The Limbo implementation of the bridge is stored in the `modules` directory.
The `qtwidgets.b` and `qtchannels.b` files are compiled as normal, either in
the hosted Inferno environment or outside it using the native `limbo` compiler.
The `qtwidgets.m` and `qtchannels.m` files are installed inside the hosted
environment within the `module` directory.

For example, if the environment variable `INFERNO_ROOT` refers to the location
of the hosted Inferno environment, you might compile and install the modules
at the command line with the following commands:

    limbo modules/*.b
    cp qt*.dis $INFERNO_ROOT/dis/lib/
    cp modules/qt*.m $INFERNO_ROOT/module/

