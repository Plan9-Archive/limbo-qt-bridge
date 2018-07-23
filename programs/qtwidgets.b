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
    sprint: import sys;

include "qtwidgets.m";

init()
{
    qtchannels = load QtChannels "/dis/lib/qtchannels.dis";
    sys = load Sys Sys->PATH;
    tables = load Tables Tables->PATH;

    channels = Channels.init();
    widget_counter = 0;
    signal_hash := Strhash[chan of string].new(23, nil);
}

get_channels(): ref Channels
{
    return channels;
}

create(class: string, args: list of string): string
{
    # Refer to the object using something that won't be reduced to an integer
    # because the Qt bridge uses a dictionary mapping strings to objects.
    proxy := sys->sprint("%s_%x", class, widget_counter);
    channels.request("create", proxy::class::args);
    widget_counter = (widget_counter + 1) & 16r0fffffff;

    return proxy;
}

forget(proxy: string)
{
    channels.request("forget", proxy::proxy::nil);
    widget_counter = (widget_counter + 1) & 16r0fffffff;
}

call(proxy, method: string, args: list of string): string
{
    return channels.request("call", proxy::method::args);
}

call_keep(proxy, method: string, args: list of string): string
{
    return channels.request("call_keep", proxy::method::args);
}

# Utility functions

quote(s: string): string
{
    return sprint("\"%s\"", s);
}

unquote(s: string): string
{
    return s[1:len(s) - 1];
}

# Proxy classes

connect[T, U](src_proxy: T, signal: string, dest_proxy: U, slot: string)
    for { T => _get_proxy: fn(w: self T):string;
          U => _invoke: fn(); }
{
    proxy := src_proxy._get_proxy();
    channels.request("connect", proxy::signal::nil);

    ### Register the destination proxy and slot.
    #signal_hash.add(proxy + " " + signal, slot);
}


QAction._get_proxy(w: self ref QAction): string
{
    return w.proxy;
}

QApplication.init(args: list of string): ref QApplication
{
    proxy := call_keep("QApplication", "instance", nil);
    return ref(QApplication(proxy));
}

QApplication.quit(w: self ref QApplication)
{
    call(w.proxy, "quit", nil);
}

QApplication._invoke()
{
}

QMainWindow.init(args: list of string): ref QMainWindow
{
    proxy := create("QMainWindow", args);
    return ref QMainWindow(proxy);
}

QMainWindow.close(w: self ref QMainWindow)
{
    call(w.proxy, "close", nil);
}

QMainWindow.menuBar(w: self ref QMainWindow): ref QMenuBar
{
    # Ensure that the return value is registered.
    value := call_keep(w.proxy, "menuBar", nil);
    return ref QMenuBar(value);
}

QMainWindow.setTitle(w: self ref QMainWindow, title: string)
{
    call(w.proxy, "setWindowTitle", quote(title)::nil);
}

QMainWindow.show(w: self ref QMainWindow)
{
    call(w.proxy, "show", nil);
}

QMenu.addAction(w: self ref QMenu, text: string): ref QAction
{
    value := call_keep(w.proxy, "addAction", quote(text)::nil);
    return ref QAction(value);
}

QMenuBar.addMenu(w: self ref QMenuBar, title: string): ref QAction
{
    value := call_keep(w.proxy, "addMenu", quote(title)::nil);
    return ref QMenu(value);
}

QWidget.init(args: list of string): ref QWidget
{
    proxy := create("QWidget", args);
    return ref QWidget(proxy);
}

QWidget.close(w: self ref QWidget)
{
    call(w.proxy, "close", nil);
}

QWidget.show(w: self ref QWidget)
{
    call(w.proxy, "show", nil);
}
