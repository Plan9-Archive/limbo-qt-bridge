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
    channels.request(enc_str("forget"), enc_str(proxy)::nil);
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
    for { T => _get_proxy: fn(w: self T): string; }
{
    channels.request(enc_str("connect"), enc_inst(src)::enc_str(signal)::nil);

    # Register the destination slot.
    proxy := src._get_proxy();
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

# Remote signal-slot connection

rconnect[T,U](src: T, signal: string, dest: U, slot: string)
    for { T => _get_proxy: fn(w: self T): string;
          U => _get_proxy: fn(w: self U): string; }
{
    channels.request(enc_str("rconnect"),
        enc_inst(src)::enc_str(signal)::enc_inst(dest)::enc_str(slot)::nil);
}

# Proxy classes

QAction._get_proxy(w: self ref QAction): string
{
    return w.proxy;
}

QApplication.new(): ref QApplication
{
    proxy := dec_str(call_static_keep("QApplication", "instance", nil));
    return ref(QApplication(proxy));
}

QApplication.quit(w: self ref QApplication)
{
    call(w.proxy, "quit", nil);
}

QBrush.enc(w: self QBrush): string
{
    return enc_value("QBrush", w.color.enc()::nil);
}

QCheckBox._get_proxy(w: self ref QCheckBox): string
{
    return w.proxy;
}

QCheckBox.new(text: string): ref QCheckBox
{
    proxy := create("QCheckBox", enc_str(text)::nil);
    return ref QCheckBox(proxy);
}

QColor.enc(w: self QColor): string
{
    values := enc_int(w.red)::enc_int(w.green)::enc_int(w.blue)::enc_int(w.alpha)::nil;
    return enc_value("QColor", values);
}

QDialog._get_proxy(w: self ref QDialog): string
{
    return w.proxy;
}

QDialog.new(): ref QDialog
{
    proxy := create("QDialog", nil);
    return ref QDialog(proxy);
}

QDialog.exec(w: self ref QDialog)
{
    call(w.proxy, "exec", nil);
}

QDialog.setLayout[T](w: self ref QDialog, layout: T)
    for { T => _get_proxy: fn(w: self T): string; }
{
    QWidget._setLayout(w, layout._get_proxy());
}

QDialog.setWindowTitle(w: self ref QDialog, title: string)
{
    QWidget._setWindowTitle(w, title);
}

QDialog.show(w: self ref QDialog)
{
    call(w.proxy, "show", nil);
}

QFileDialog.getOpenFileName[T](parent: T, caption, dir, filter: string): (string, string)
    for { T => _get_proxy: fn(w: self T): string; }
{
    value := call_static("QFileDialog", "getOpenFileName",
        enc_inst(parent)::enc_str(caption)::enc_str(dir)::
        enc_str(filter)::nil);

    return parse_2tuple(value);
}

QGridLayout._get_proxy(w: self ref QGridLayout): string
{
    return w.proxy;
}

QGridLayout.new(): ref QGridLayout
{
    proxy := create("QGridLayout", nil);
    return ref QGridLayout(proxy);
}

QGridLayout.addWidget[T](w: self ref QGridLayout, widget: T, row, column, rowspan, colspan: int)
    for { T => _get_proxy: fn(w: self T): string; }
{
    call(w.proxy, "addWidget",
        enc_inst(widget)::enc_int(row)::enc_int(column)::enc_int(rowspan)::enc_int(colspan)::nil);
}

QGridLayout.addLayout[T](w: self ref QGridLayout, widget: T, row, column, rowspan, colspan: int)
    for { T => _get_proxy: fn(w: self T): string; }
{
    call(w.proxy, "addLayout",
        enc_inst(widget)::enc_int(row)::enc_int(column)::enc_int(rowspan)::enc_int(colspan)::nil);
}

QGroupBox._get_proxy(w: self ref QGroupBox): string
{
    return w.proxy;
}

QGroupBox.new(title: string): ref QGroupBox
{
    proxy := create("QGroupBox", enc_str(title)::nil);
    return ref QGroupBox(proxy);
}

QGroupBox.setLayout[T](w: self ref QGroupBox, layout: T)
    for { T => _get_proxy: fn(w: self T): string; }
{
    QWidget._setLayout(w, layout._get_proxy());
}

QHBoxLayout._get_proxy(w: self ref QHBoxLayout): string
{
    return w.proxy;
}

QHBoxLayout.new(): ref QHBoxLayout
{
    proxy := create("QHBoxLayout", nil);
    return ref QHBoxLayout(proxy);
}

QHBoxLayout.addWidget[T](w: self ref QHBoxLayout, widget: T)
    for { T => _get_proxy: fn(w: self T): string; }
{
    call(w.proxy, "addWidget", enc_inst(widget)::nil);
}

QHBoxLayout.addLayout[T](w: self ref QHBoxLayout, widget: T)
    for { T => _get_proxy: fn(w: self T): string; }
{
    call(w.proxy, "addLayout", enc_inst(widget)::nil);
}

QLabel._get_proxy(w: self ref QLabel): string
{
    return w.proxy;
}

QLabel.new(): ref QLabel
{
    proxy := create("QLabel", nil);
    return ref QLabel(proxy);
}

QLabel.setAlignment(w: self ref QLabel, alignment: int)
{
    call(w.proxy, "setAlignment", enc_enum("Alignment", alignment)::nil);
}

QLabel.setPixmap[T](w: self ref QLabel, pixmap: T)
    for { T => _get_proxy: fn(w: self T): string; }
{
    call(w.proxy, "setPixmap", enc_inst(pixmap)::nil);
}

QLabel.setText(w: self ref QLabel, text: string)
{
    call(w.proxy, "setText", enc_str(text)::nil);
}

QMainWindow._get_proxy(w: self ref QMainWindow): string
{
    return w.proxy;
}

QMainWindow.new(): ref QMainWindow
{
    proxy := create("QMainWindow", nil);
    return ref QMainWindow(proxy);
}

QMainWindow.close(w: self ref QMainWindow)
{
    QWidget._close(w);
}

QMainWindow.menuBar(w: self ref QMainWindow): ref QMenuBar
{
    # Ensure that the return value is registered.
    value := dec_str(call_keep(w.proxy, "menuBar", nil));
    return ref QMenuBar(value);
}

QMainWindow.resize(w: self ref QMainWindow, width, height: int)
{
    QWidget._resize(w, width, height);
}

QMainWindow.setCentralWidget[T](w: self ref QMainWindow, widget: T)
    for { T => _get_proxy: fn(w: self T): string; }
{
    call(w.proxy, "setCentralWidget", enc_inst(widget)::nil);
}

QMainWindow.setWindowTitle(w: self ref QMainWindow, title: string)
{
    QWidget._setWindowTitle(w, title);
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

QMenuBar.addMenu(w: self ref QMenuBar, title: string): ref QMenu
{
    value := dec_str(call_keep(w.proxy, "addMenu", enc_str(title)::nil));
    return ref QMenu(value);
}

QPainter.new(): ref QPainter
{
    proxy := create("QPainter", nil);
    return ref QPainter(proxy);
}

QPainter.begin[T](w: self ref QPainter, device: T)
    for { T => _get_proxy: fn(w: self T): string; }
{
    call(w.proxy, "begin", enc_inst(device)::nil);
}

QPainter.drawRect(w: self ref QPainter, x, y, width, height: int)
{
    call(w.proxy, "drawRect", enc_int(x)::enc_int(y)::enc_int(width)::enc_int(height)::nil);
}

QPainter.drawText(w: self ref QPainter, x, y: int, text: string)
{
    call(w.proxy, "drawText", enc_int(x)::enc_int(y)::enc_str(text)::nil);
}

QPainter.end(w: self ref QPainter)
{
    call(w.proxy, "end", nil);
    forget(w.proxy);
}

QPainter.setBrush(w: self ref QPainter, brush: QBrush)
{
    call(w.proxy, "setBrush", brush.enc()::nil);
}

QPainter.setPen(w: self ref QPainter, pen: QPen)
{
    call(w.proxy, "setPen", pen.enc()::nil);
}

QPen.enc(w: self QPen): string
{
    return enc_value("QPen", w.color.enc()::nil);
}

QPixmap._get_proxy(w: self ref QPixmap): string
{
    return w.proxy;
}

QPixmap.new(width, height: int): ref QPixmap
{
    proxy := create("QPixmap", enc_int(width)::enc_int(height)::nil);
    return ref QPixmap(proxy);
}

QPixmap.fill(w: self ref QPixmap, color: QColor)
{
    call(w.proxy, "fill", color.enc()::nil);
}

QPushButton._get_proxy(w: self ref QPushButton): string
{
    return w.proxy;
}

QPushButton.new(text: string): ref QPushButton
{
    proxy := create("QPushButton", enc_str(text)::nil);
    return ref QPushButton(proxy);
}

QRadioButton._get_proxy(w: self ref QRadioButton): string
{
    return w.proxy;
}

QRadioButton.new(text: string): ref QRadioButton
{
    proxy := create("QRadioButton", enc_str(text)::nil);
    return ref QRadioButton(proxy);
}

QTextEdit._get_proxy(w: self ref QTextEdit): string
{
    return w.proxy;
}

QTextEdit.new(): ref QTextEdit
{
    proxy := create("QTextEdit", nil);
    return ref QTextEdit(proxy);
}

QTextEdit.setText(w: self ref QTextEdit, text: string)
{
    call(w.proxy, "setText", enc_str(text)::nil);
}

QVBoxLayout._get_proxy(w: self ref QVBoxLayout): string
{
    return w.proxy;
}

QVBoxLayout.new(): ref QVBoxLayout
{
    proxy := create("QVBoxLayout", nil);
    return ref QVBoxLayout(proxy);
}

QVBoxLayout.addWidget[T](w: self ref QVBoxLayout, widget: T)
    for { T => _get_proxy: fn(w: self T): string; }
{
    call(w.proxy, "addWidget", enc_inst(widget)::nil);
}

QVBoxLayout.addLayout[T](w: self ref QVBoxLayout, widget: T)
    for { T => _get_proxy: fn(w: self T): string; }
{
    call(w.proxy, "addLayout", enc_inst(widget)::nil);
}

QWidget._get_proxy(w: self ref QWidget): string
{
    return w.proxy;
}

QWidget._close[T](w: T)
    for { T => _get_proxy: fn(w: self T): string; }
{
    call(w._get_proxy(), "close", nil);
}

QWidget._resize[T](w: T, width, height: int)
    for { T => _get_proxy: fn(w: self T): string; }
{
    call(w._get_proxy(), "resize", enc_int(width)::enc_int(height)::nil);
}

QWidget._setLayout[T](w: T, layout: string)
    for { T => _get_proxy: fn(w: self T): string; }
{
    call(w._get_proxy(), "setLayout", enc(layout, "I")::nil);
}

QWidget._setWindowTitle[T](w: T, title: string)
    for { T => _get_proxy: fn(w: self T): string; }
{
    call(w._get_proxy(), "setWindowTitle", enc_str(title)::nil);
}

QWidget.new(): ref QWidget
{
    proxy := create("QWidget", nil);
    return ref QWidget(proxy);
}

QWidget.close(w: self ref QWidget)
{
    QWidget._close(w);
}

QWidget.resize(w: self ref QWidget, width, height: int)
{
    QWidget._resize(w, width, height);
}

QWidget.setLayout[T](w: self ref QWidget, layout: T)
    for { T => _get_proxy: fn(w: self T): string; }
{
    QWidget._setLayout(w, layout._get_proxy());
}

QWidget.setWindowTitle(w: self ref QWidget, title: string)
{
    QWidget._setWindowTitle(w, title);
}

QWidget.show(w: self ref QWidget)
{
    call(w.proxy, "show", nil);
}