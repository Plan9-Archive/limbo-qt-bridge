Limbo to Qt Bridge
==================

This repository contains a collection of Python 3 and Limbo modules that
implement a bridge that allows Limbo applications running in a hosted Inferno
environment to access the Qt framework to construct a graphical user interface.

The host side of the bridge is implemented in Python 3 using the PyQt 5
bindings to the Qt 5 libraries. This manages the GUI objects that are presented
to the user, performs method calls on behalf of the Limbo application and
dispatches signals and events across the bridge.

On the Limbo side, a framework of functions and ADTs provide the infrastructure
needed to communicate with the host over the applications `stdin` and `stdout`
file descriptors. The Qt classes and methods exposed to the Limbo application
are defined as ADTs, providing a class-like API that should be familiar to
developers with Qt experience.


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


Running the examples
--------------------

It should then be possible to compile the examples using the `limbo` executable
for the host. However, the examples are designed to be packaged using the
Standalone Executable Packager for Limbo Programs in order to be run using the
bridge. You can obtain the packager from this repository:

  https://bitbucket.org/dboddie/limbo-executable-packager

By running the `package.py` tool from its location in a local copy of that
repository, an example can be packaged in the following way:

    limbo-executable-packager/package.py $INFERNO_ROOT examples/widgets.b /tmp/le

Assuming that this is successful and that the `/tmp/le` executable is created,
it can be run by passing it as an argument to the `qtbridge.py` tool:

    ./qtbridge.py /tmp/le

If all goes well, a simple graphical user interface should be displayed.


Debugging
---------

A simple way to check whether communication over the bridge works is to pass
the `--debug` option to the `qtbridge.py` tool. This will cause a log window to
be shown containing the messages sent and received at the Python end of the
communication.


License
-------

This software is licensed under the Expat/MIT license:

  Copyright (C) 2018 David Boddie <david@boddie.org.uk>

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to
  deal in the Software without restriction, including without limitation the
  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
  sell copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
  DEALINGS IN THE SOFTWARE.

The examples
