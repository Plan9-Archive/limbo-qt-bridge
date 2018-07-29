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

