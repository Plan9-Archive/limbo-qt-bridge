# qtwidgets.b
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

# Define an data type to represent a widget.

implement QtWidgets;

include "sys.m";
    sys: Sys;

include "qtwidgets.m";

init()
{
    qtchannels = load QtChannels "/dis/lib/qtchannels.dis";
    sys = load Sys Sys->PATH;

    channels = Channels.init();
    counter = 0;
}

get_channels(): ref Channels
{
    return channels;
}

Proxy.init(class: string, args: list of string): ref Proxy
{
    # Refer to the object using something that won't be reduced to an integer
    # because the Qt bridge uses a dictionary mapping strings to objects.
    name := sys->sprint("obj%x", counter);
    channels.request("create", name, class, args);
    counter = (counter + 1) & 16r0fffffff;

    return ref Proxy(name);
}

Proxy.call(p: self ref Proxy, method: string, args: list of string): string
{
    return channels.request("call", p.name, method, args);
}


QWidget.init(args: list of string): ref QWidget
{
    proxy := Proxy.init("QWidget", args);
    return ref QWidget(proxy);
}

QWidget.close(w: self ref QWidget)
{
    w.proxy.call("close", nil);
}

QWidget.show(w: self ref QWidget)
{
    w.proxy.call("show", nil);
}
