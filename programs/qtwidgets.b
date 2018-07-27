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

include "string.m";
    str: String;

include "qtwidgets.m";

init()
{
    qtchannels = load QtChannels "/dis/lib/qtchannels.dis";
    sys = load Sys Sys->PATH;
    tables = load Tables Tables->PATH;
    str = load String String->PATH;

    channels = Channels.init();
    tr_counter = 0;

    # Keep a record of signal-slot connections.
    signal_hash = Strhash[list of Invokable].new(23, nil);

    # Register a channel with the communication object that will be used to
    # receive notifications about signals.
    signal_ch := chan of string;
    channels.response_hash.add(0, signal_ch);

    spawn dispatcher(signal_ch);
}

get_channels(): ref Channels
{
    return channels;
}

create(class: string, args: list of string): string
{
    # Refer to the object using something that won't be reduced to an integer
    # because the Qt bridge uses a dictionary mapping strings to objects.
    proxy := sys->sprint("%s_%x", class, tr_counter);
    channels.request(enc_str("create"), enc(proxy, "s")::enc(class, "C")::args);
    tr_counter = (tr_counter + 1) & 16r0fffffff;

    return proxy;
}

forget(proxy: string)
{
    channels.request(enc_str("forget"), enc(proxy, "I")::enc(proxy, "I")::nil);
    tr_counter = (tr_counter + 1) & 16r0fffffff;
}

call(proxy, method: string, args: list of string): string
{
    return channels.request(enc_str("call"), enc(proxy, "I")::enc_str(method)::args);
}

call_static(proxy, method: string, args: list of string): string
{
    return channels.request(enc_str("call"), enc(proxy, "C")::enc_str(method)::args);
}

call_keep(proxy, method: string, args: list of string): string
{
    return channels.request(enc_str("call_keep"), enc(proxy, "I")::enc_str(method)::args);
}

call_static_keep(proxy, method: string, args: list of string): string
{
    return channels.request(enc_str("call_keep"), enc(proxy, "C")::enc_str(method)::args);
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

debug_msg(s: string)
{
    msg := sprint("s5 debug i4 9999 s%d '%s'", len s + 2, s);
    sys->print("%d %s", len msg, msg);
}

# Signal-slot connection and dispatch

connect[T](src: T, signal: string, slot: Invokable)
    for { T => _get_proxy: fn(w: self T):string; }
{
    proxy := src._get_proxy();
    channels.request(enc_str("connect"), enc(proxy, "I")::enc_str(signal)::nil);

    # Register the destination slot.
    l := signal_hash.find(proxy + " " + signal);
    if (l == nil)
        l = list of { slot };
    else
        l = slot::l;

    signal_hash.add(proxy + " " + signal, l);
}

dispatcher(signal_ch: chan of string)
{
    for (;;) alt {
        s := <- signal_ch =>
            # Split the key (the first two words in the reply) from the signal
            # arguments (the rest).
            type_, src, signal : string;

            (type_, src, s) = parse_arg(s);
            (type_, signal, s) = parse_arg(s);
            key := src + " " + signal;

            # Find the list of slots in the hash and call each of them with the
            # list of arguments.
            slots := signal_hash.find(key);

            for (; slots != nil; slots = tl slots)
                (hd slots)(str->unquoted(s));
    }
}

# Proxy classes

QAction._get_proxy(w: self ref QAction): string
{
    return w.proxy;
}

QApplication.init(): ref QApplication
{
    proxy := dec_str(call_static_keep("QApplication", "instance", nil));
    return ref(QApplication(proxy));
}

QApplication.quit(w: self ref QApplication)
{
    call(w.proxy, "quit", nil);
}

QFileDialog.getOpenFileName[T](parent: T, caption, dir, filter: string): (string, string)
    for { T => _get_proxy: fn(w: self T): string; }
{
    value := call_static("QFileDialog", "getOpenFileName",
        enc(parent._get_proxy(), "I")::enc_str(caption)::enc_str(dir)::
        enc_str(filter)::nil);

    return parse_2tuple(value);
}

QMainWindow._get_proxy(w: self ref QMainWindow): string
{
    return w.proxy;
}

QMainWindow.init(): ref QMainWindow
{
    proxy := create("QMainWindow", nil);
    return ref QMainWindow(proxy);
}

QMainWindow.close(w: self ref QMainWindow)
{
    QWidget._close(w.proxy);
}

QMainWindow.menuBar(w: self ref QMainWindow): ref QMenuBar
{
    # Ensure that the return value is registered.
    value := dec_str(call_keep(w.proxy, "menuBar", nil));
    return ref QMenuBar(value);
}

QMainWindow.resize(w: self ref QMainWindow, width, height: int)
{
    QWidget._resize(w.proxy, width, height);
}

QMainWindow.setCentralWidget[T](w: self ref QMainWindow, widget: T)
    for { T => _get_proxy: fn(w: self T): string; }
{
    call(w.proxy, "setCentralWidget", enc(widget._get_proxy(), "I")::nil);
}

QMainWindow.setWindowTitle(w: self ref QMainWindow, title: string)
{
    QWidget._setWindowTitle(w.proxy, title);
}

QMainWindow.show(w: self ref QMainWindow)
{
    call(w.proxy, "show", nil);
}

QMenu.addAction(w: self ref QMenu, text: string): ref QAction
{
    value := dec_str(call_keep(w.proxy, "addAction", enc_str(text)::nil));
    return ref QAction(value);
}

QMenuBar.addMenu(w: self ref QMenuBar, title: string): ref QAction
{
    value := dec_str(call_keep(w.proxy, "addMenu", enc_str(title)::nil));
    return ref QMenu(value);
}

QTextEdit._get_proxy(w: self ref QTextEdit): string
{
    return w.proxy;
}

QTextEdit.init(): ref QTextEdit
{
    proxy := create("QTextEdit", nil);
    return ref QTextEdit(proxy);
}

QTextEdit.setText(w: self ref QTextEdit, text: string)
{
    call(w.proxy, "setText", enc_str(text)::nil);
}

QWidget._close(proxy: string)
{
    call(proxy, "close", nil);
}

QWidget._resize(proxy: string, width, height: int)
{
    call(proxy, "resize", enc_int(width)::enc_int(height)::nil);
}

QWidget._setWindowTitle(proxy, title: string)
{
    call(proxy, "setWindowTitle", enc_str(title)::nil);
}

QWidget.init(): ref QWidget
{
    proxy := create("QWidget", nil);
    return ref QWidget(proxy);
}

QWidget.close(w: self ref QWidget)
{
    QWidget._close(w.proxy);
}

QWidget.resize(w: self ref QWidget, width, height: int)
{
    QWidget._resize(w.proxy, width, height);
}

QWidget.show(w: self ref QWidget)
{
    call(w.proxy, "show", nil);
}
