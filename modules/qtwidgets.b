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

NoReturnValue, ReturnValue : con iota;

init()
{
    qtchannels = load QtChannels "/dis/lib/qtchannels.dis";
    sys = load Sys Sys->PATH;
    tables = load Tables Tables->PATH;
    str = load String String->PATH;

    channels = Channels.init();
    tr_counter = 0;
}

get_channels(): ref Channels
{
    return channels;
}

qdebug(s: string)
{
    qtchannels->debug_msg(s);
}

create(class: string, args: list of string): string
{
    # Refer to the object using something that won't be reduced to an integer
    # because the Qt bridge uses a dictionary mapping strings to objects.
    proxy := sys->sprint("%s_%x", class, tr_counter);
    channels.request(enc_str("create"),
        enc(proxy, "s")::enc(class, "C")::args, NoReturnValue);
    tr_counter = (tr_counter + 1) & 16r0fffffff;

    return proxy;
}

forget[T](obj: T)
    for { T => _get_proxy: fn(w: self T): string; }
{
    forget_proxy(obj._get_proxy());
}

forget_proxy(proxy: string)
{
    channels.request(enc_str("forget"), enc_str(proxy)::nil, NoReturnValue);
}

call(proxy, method: string, args: list of string): string
{
    return channels.request(enc_str("call"),
        enc_str("")::enc(proxy, "I")::enc_str(method)::args, ReturnValue);
}

call_static(proxy, method: string, args: list of string): string
{
    return channels.request(enc_str("call"),
        enc_str("")::enc(proxy, "C")::enc_str(method)::args, ReturnValue);
}

call_keep(proxy, method: string, args: list of string): string
{
    return channels.request(enc_str("call"),
        enc_str("k")::enc(proxy, "I")::enc_str(method)::args, ReturnValue);
}

call_static_keep(proxy, method: string, args: list of string): string
{
    return channels.request(enc_str("call"),
        enc_str("k")::enc(proxy, "C")::enc_str(method)::args, ReturnValue);
}

call_value(proxy, method: string, args: list of string, unpack_names: list of string): string
{
    # Encode the names of members of the return value in the flags string.
    # For example: v,width,height
    flags := "v";
    for (; unpack_names != nil; unpack_names = tl unpack_names)
        flags += "," + (hd unpack_names);

    return channels.request(enc_str("call"),
        enc_str(flags)::enc(proxy, "I")::enc_str(method)::args, ReturnValue);
}

# Signal-slot connection and dispatch

connect[T](src: T, signal: string, slot: Invokable)
    for { T => _get_proxy: fn(w: self T): string; }
{
    # Obtain a channel to use to receive a response.
    (id_, response_ch) := channels.get_persistent();

    # Send the call request and receive the response.
    message := enc_str("connect") + enc_int(id_) + enc_inst(src) + enc_str(signal);
    message[len message - 1] = '\n';

    channels.write_ch <-= message;

    # Read and discard the response. The next time this channel will be used it
    # will be to receive a signal.
    value := <- response_ch;

    spawn signal_dispatcher(id_, response_ch, slot);
}

signal_dispatcher(id_: int, signal_ch: chan of string, slot: Invokable)
{
    for (;;) alt {
        s := <- signal_ch =>

            args := parse_args(s);
            slot(args);

            # Inform Qt that the signal has been processed. This is similar to
            # how the event dispatcher tidies up after calling an event handler.
            # We create the message ourselves in order to use the identifier we
            # acquired for the connection.
            message := enc_str("process") + enc_int(id_);
            message[len message - 1] = '\n';
            channels.write_ch <-= message;
    }
}

# Remote signal-slot connection

rconnect[T,U](src: T, signal: string, dest: U, slot: string)
    for { T => _get_proxy: fn(w: self T): string;
          U => _get_proxy: fn(w: self U): string; }
{
    channels.request(enc_str("rconnect"),
        enc_inst(src)::enc_str(signal)::enc_inst(dest)::enc_str(slot)::nil,
        ReturnValue);
}

# Event filter creation and dispatch

filter_event[T](src: T, event_type: int, handler: EventHandler)
    for { T => _get_proxy: fn(w: self T): string; }
{
    # Obtain a channel to use to receive a response.
    (id_, response_ch) := channels.get_persistent();

    # Send the call request and receive the response.
    message := enc_str("filter") + enc_int(id_) + enc_inst(src) + enc_int(event_type);
    message[len message - 1] = '\n';

    channels.write_ch <-= message;

    # Read and discard the response. The next time this channel will be used it
    # will be to receive an event.
    value := <- response_ch;

    spawn event_dispatcher(id_, response_ch, handler);
}

event_dispatcher(id_: int, event_ch: chan of string, handler: EventHandler)
{
    for (;;) alt {
        s := <- event_ch =>
            # Call the handler, passing a proxy string for the event so that
            # it can be accessed. The Qt side of the bridge will queue pending
            # events with the identifier until the event is deleted, which
            # occurs when we call forget. This avoids the situation where
            # another event arrives while one is being processed, causing the
            # message reader to block because this qualifier is still active.
            proxy := dec_str(s);
            handler(proxy);
            # The forget request does not expect a response, so any pending
            # event messages that arrive immediately will not block it.
            forget_proxy(proxy);
    }
}

# Proxy classes

QAction._get_proxy(w: self ref QAction): string
{
    return w.proxy;
}

QAction.setShortcut(w: self ref QAction, keys: string)
{
    call(w.proxy, "setShortcut", enc_str(keys)::nil);
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
    QWidget._setLayout(w, layout);
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

QFont._get_proxy(w: self ref QFont): string
{
    return w.proxy;
}

QFont.new(): ref QFont
{
    proxy := create("QFont", nil);
    return ref QFont(proxy);
}

QFont.setFamily(w: self ref QFont, family: string)
{
    call(w.proxy, "setFamily", enc_str(family)::nil);
}

QFont.setPixelSize(w: self ref QFont, size: int)
{
    call(w.proxy, "setPixelSize", enc_int(size)::nil);
}

QFont.setPointSize(w: self ref QFont, size: real)
{
    # Note that we call setPointSizeF instead of setPointSize.
    call(w.proxy, "setPointSizeF", enc_real(size)::nil);
}

QGraphicsEllipseItem._get_proxy(w: self ref QGraphicsEllipseItem): string
{
    return w.proxy;
}

QGraphicsEllipseItem.setBrush(w: self ref QGraphicsEllipseItem, brush: QBrush)
{
    call(w.proxy, "setBrush", brush.enc()::nil);
}

QGraphicsEllipseItem.setPen(w: self ref QGraphicsEllipseItem, pen: QPen)
{
    call(w.proxy, "setPen", pen.enc()::nil);
}

QGraphicsEllipseItem.setPos(w: self ref QGraphicsEllipseItem, x, y: real)
{
    call(w.proxy, "setPos", enc_real(x)::enc_real(y)::nil);
}

QGraphicsLineItem._get_proxy(w: self ref QGraphicsLineItem): string
{
    return w.proxy;
}

QGraphicsLineItem.setPen(w: self ref QGraphicsLineItem, pen: QPen)
{
    call(w.proxy, "setPen", pen.enc()::nil);
}

QGraphicsLineItem.setPos(w: self ref QGraphicsLineItem, x, y: real)
{
    call(w.proxy, "setPos", enc_real(x)::enc_real(y)::nil);
}

QGraphicsRectItem._get_proxy(w: self ref QGraphicsRectItem): string
{
    return w.proxy;
}

QGraphicsRectItem.setBrush(w: self ref QGraphicsRectItem, brush: QBrush)
{
    call(w.proxy, "setBrush", brush.enc()::nil);
}

QGraphicsRectItem.setPen(w: self ref QGraphicsRectItem, pen: QPen)
{
    call(w.proxy, "setPen", pen.enc()::nil);
}

QGraphicsRectItem.setPos(w: self ref QGraphicsRectItem, x, y: real)
{
    call(w.proxy, "setPos", enc_real(x)::enc_real(y)::nil);
}

QGraphicsSimpleTextItem._get_proxy(w: self ref QGraphicsSimpleTextItem): string
{
    return w.proxy;
}

QGraphicsSimpleTextItem.setBrush(w: self ref QGraphicsSimpleTextItem, brush: QBrush)
{
    call(w.proxy, "setBrush", brush.enc()::nil);
}

QGraphicsSimpleTextItem.setFont(w: self ref QGraphicsSimpleTextItem, font: ref QFont)
{
    call(w.proxy, "setFont", enc_inst(font)::nil);
}

QGraphicsSimpleTextItem.setPen(w: self ref QGraphicsSimpleTextItem, pen: QPen)
{
    call(w.proxy, "setPen", pen.enc()::nil);
}

QGraphicsSimpleTextItem.setPos(w: self ref QGraphicsSimpleTextItem, x, y: real)
{
    call(w.proxy, "setPos", enc_real(x)::enc_real(y)::nil);
}

QGraphicsTextItem._get_proxy(w: self ref QGraphicsTextItem): string
{
    return w.proxy;
}

QGraphicsTextItem.setBrush(w: self ref QGraphicsTextItem, brush: QBrush)
{
    call(w.proxy, "setBrush", brush.enc()::nil);
}

QGraphicsTextItem.setFont(w: self ref QGraphicsTextItem, font: ref QFont)
{
    call(w.proxy, "setFont", enc_inst(font)::nil);
}

QGraphicsTextItem.setPen(w: self ref QGraphicsTextItem, pen: QPen)
{
    call(w.proxy, "setPen", pen.enc()::nil);
}

QGraphicsTextItem.setPos(w: self ref QGraphicsTextItem, x, y: real)
{
    call(w.proxy, "setPos", enc_real(x)::enc_real(y)::nil);
}

QGraphicsScene._get_proxy(w: self ref QGraphicsScene): string
{
    return w.proxy;
}

QGraphicsScene.new(): ref QGraphicsScene
{
    proxy := create("QGraphicsScene", nil);
    return ref QGraphicsScene(proxy);
}

QGraphicsScene.addEllipse(w: self ref QGraphicsScene, x, y, width, height: real): ref QGraphicsEllipseItem
{
    value := dec_str(call_keep(w.proxy, "addEllipse",
        enc_real(x)::enc_real(y)::enc_real(width)::enc_real(height)::nil));
    return ref QGraphicsEllipseItem(value);
}

QGraphicsScene.addLine(w: self ref QGraphicsScene, x1, y1, x2, y2: real): ref QGraphicsLineItem
{
    value := dec_str(call_keep(w.proxy, "addLine",
        enc_real(x1)::enc_real(y1)::enc_real(x2)::enc_real(y2)::nil));
    return ref QGraphicsLineItem(value);
}

QGraphicsScene.addRect(w: self ref QGraphicsScene, x, y, width, height: real): ref QGraphicsRectItem
{
    value := dec_str(call_keep(w.proxy, "addRect",
        enc_real(x)::enc_real(y)::enc_real(width)::enc_real(height)::nil));
    return ref QGraphicsRectItem(value);
}

QGraphicsScene.addSimpleText(w: self ref QGraphicsScene, text: string): ref QGraphicsSimpleTextItem
{
    value := dec_str(call_keep(w.proxy, "addSimpleText", enc_str(text)::nil));
    return ref QGraphicsSimpleTextItem(value);
}

QGraphicsScene.addText(w: self ref QGraphicsScene, text: string): ref QGraphicsTextItem
{
    value := dec_str(call_keep(w.proxy, "addText", enc_str(text)::nil));
    return ref QGraphicsTextItem(value);
}

QGraphicsView._get_proxy(w: self ref QGraphicsView): string
{
    return w.proxy;
}

QGraphicsView.new(): ref QGraphicsView
{
    proxy := create("QGraphicsView", nil);
    return ref QGraphicsView(proxy);
}

QGraphicsView.setDragMode(w: self ref QGraphicsView, dragMode: int)
{
    call(w.proxy, "setDragMode", enc_int(dragMode)::nil);
}

QGraphicsView.scale(w: self ref QGraphicsView, sx, sy: real)
{
    call(w.proxy, "scale", enc_real(sx)::enc_real(sy)::nil);
}

QGraphicsView.setRenderHint(w: self ref QGraphicsView, hint: int)
{
    call(w.proxy, "setRenderHint", enc_int(hint)::nil);
}

QGraphicsView.setScene(w: self ref QGraphicsView, scene: ref QGraphicsScene)
{
    call(w.proxy, "setScene", enc_inst(scene)::nil);
}

QGraphicsView.setSceneRect(w: self ref QGraphicsView, x, y, width, height: real)
{
    call(w.proxy, "setSceneRect", enc_real(x)::enc_real(y)::enc_real(width)::enc_real(height)::nil);
}

QGraphicsView.setTransform(w: self ref QGraphicsView, transform: ref QTransform)
{
    call(w.proxy, "setTransform", enc_inst(transform)::nil);
}

QGraphicsView.translate(w: self ref QGraphicsView, dx, dy: real)
{
    call(w.proxy, "translate", enc_real(dx)::enc_real(dy)::nil);
}

QGraphicsView.viewport(w: self ref QGraphicsView): ref QWidget
{
    proxy := dec_str(call_keep(w.proxy, "viewport", nil));
    return ref QWidget(proxy);
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

QGridLayout.setContentsMargins(w: self ref QGridLayout, left, top, right, bottom: int)
{
    call(w.proxy, "setContentsMargins", enc_int(left)::enc_int(top)::enc_int(right)::enc_int(bottom)::nil);
}

QGridLayout.setSpacing(w: self ref QGridLayout, spacing: int)
{
    call(w.proxy, "setSpacing", enc_int(spacing)::nil);
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
    QWidget._setLayout(w, layout);
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

QHBoxLayout.setContentsMargins(w: self ref QHBoxLayout, left, top, right, bottom: int)
{
    call(w.proxy, "setContentsMargins", enc_int(left)::enc_int(top)::enc_int(right)::enc_int(bottom)::nil);
}

QHBoxLayout.setSpacing(w: self ref QHBoxLayout, spacing: int)
{
    call(w.proxy, "setSpacing", enc_int(spacing)::nil);
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

QLabel.resize(w: self ref QLabel, width, height: int)
{
    QWidget._resize(w, width, height);
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

QLabel.setWindowTitle(w: self ref QLabel, title: string)
{
    QWidget._setWindowTitle(w, title);
}

QLabel.show(w: self ref QLabel)
{
    QWidget._show(w);
}

QLabel.size(w: self ref QLabel): (int, int)
{
    return QWidget._size(w);
}

QLineEdit._get_proxy(w: self ref QLineEdit): string
{
    return w.proxy;
}

QLineEdit.new(): ref QLineEdit
{
    proxy := create("QLineEdit", nil);
    return ref QLineEdit(proxy);
}

QLineEdit.clear(w: self ref QLineEdit)
{
    call(w.proxy, "clear", nil);
}

QLineEdit.text(w: self ref QLineEdit): string
{
    value := call(w.proxy, "text", nil);
    return dec_str(value);
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

QMouseEvent.button(e: self ref QMouseEvent): int
{
    value := call(e.proxy, "button", nil);
    return dec_int(value);
}

QMouseEvent.type_(e: self ref QMouseEvent): int
{
    value := call(e.proxy, "type", nil);
    return dec_int(value);
}

QMouseEvent.x(e: self ref QMouseEvent): int
{
    value := call(e.proxy, "x", nil);
    return dec_int(value);
}

QMouseEvent.y(e: self ref QMouseEvent): int
{
    value := call(e.proxy, "y", nil);
    return dec_int(value);
}

QPainter._get_proxy(w: self ref QPainter): string
{
    return w.proxy;
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

QPainter.drawEllipse(w: self ref QPainter, x1, y1, x2, y2: int)
{
    call(w.proxy, "drawEllipse", enc_int(x1)::enc_int(y1)::enc_int(x2)::enc_int(y2)::nil);
}

QPainter.drawLine(w: self ref QPainter, x, y, width, height: int)
{
    call(w.proxy, "drawLine", enc_int(x)::enc_int(y)::enc_int(width)::enc_int(height)::nil);
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
    forget(w);
}

QPainter.setBrush(w: self ref QPainter, brush: QBrush)
{
    call(w.proxy, "setBrush", brush.enc()::nil);
}

QPainter.setPen(w: self ref QPainter, pen: QPen)
{
    call(w.proxy, "setPen", pen.enc()::nil);
}

QPainter.setRenderHint(w: self ref QPainter, hint: int)
{
    call(w.proxy, "setRenderHint", enc_int(hint)::nil);
}

QPen.enc(w: self QPen): string
{
    return enc_value("QPen", w.color.enc()::enc_int(w.width)::nil);
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

QPixmap.size(w: self ref QPixmap): (int, int)
{
    return QWidget._size(w);
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

QResizeEvent.oldSize(e: self ref QResizeEvent): (int, int)
{
    value := call_value(e.proxy, "oldSize", nil, "width"::"height"::nil);
    (w, h) := parse_2tuple(value);
    return (int w, int h);
}

QResizeEvent.size(e: self ref QResizeEvent): (int, int)
{
    value := call_value(e.proxy, "size", nil, "width"::"height"::nil);
    (w, h) := parse_2tuple(value);
    return (int w, int h);
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

QTextEdit.append(w: self ref QTextEdit, text: string)
{
    call(w.proxy, "append", enc_str(text)::nil);
}

QTextEdit.isReadOnly(w: self ref QTextEdit): int
{
    value := call(w.proxy, "isReadOnly", nil);
    return dec_bool(value);
}

QTextEdit.setText(w: self ref QTextEdit, text: string)
{
    call(w.proxy, "setText", enc_str(text)::nil);
}

QTextEdit.setReadOnly(w: self ref QTextEdit, enable: int)
{
    call(w.proxy, "setReadOnly", enc_bool(enable)::nil);
}

QTransform._get_proxy(w: self ref QTransform): string
{
    return w.proxy;
}

QTransform.new(): ref QTransform
{
    proxy := create("QTransform", nil);
    return ref QTransform(proxy);
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

QVBoxLayout.setContentsMargins(w: self ref QVBoxLayout, left, top, right, bottom: int)
{
    call(w.proxy, "setContentsMargins", enc_int(left)::enc_int(top)::enc_int(right)::enc_int(bottom)::nil);
}

QVBoxLayout.setSpacing(w: self ref QVBoxLayout, spacing: int)
{
    call(w.proxy, "setSpacing", enc_int(spacing)::nil);
}

QWheelEvent.buttons(e: self ref QWheelEvent): int
{
    value := call(e.proxy, "buttons", nil);
    return dec_int(value);
}

QWheelEvent.angleDelta(e: self ref QWheelEvent): int
{
    # angleDelta returns a QPoint but we only want the y component.
    value := call_value(e.proxy, "angleDelta", nil, "x"::"y"::nil);
    (x, y) := parse_2tuple(value);
    return int y;
}

QWheelEvent.x(e: self ref QWheelEvent): int
{
    value := call(e.proxy, "x", nil);
    return dec_int(value);
}

QWheelEvent.y(e: self ref QWheelEvent): int
{
    value := call(e.proxy, "y", nil);
    return dec_int(value);
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

QWidget._setFixedSize[T](w: T, width, height: int)
    for { T => _get_proxy: fn(w: self T): string; }
{
    call(w._get_proxy(), "setFixedSize", enc_int(width)::enc_int(height)::nil);
}

QWidget._setFocusProxy[T,U](w: T, proxy: U)
    for { T => _get_proxy: fn(w: self T): string;
          U => _get_proxy: fn(w: self U): string; }
{
    call(w._get_proxy(), "setFocusProxy", enc_inst(proxy)::nil);
}

QWidget._setLayout[T](w: T, layout: T)
    for { T => _get_proxy: fn(w: self T): string; }
{
    call(w._get_proxy(), "setLayout", enc_inst(layout)::nil);
}

QWidget._setMouseTracking[T](w: T, enable: int)
    for { T => _get_proxy: fn(w: self T): string; }
{
    call(w._get_proxy(), "setMouseTracking", enc_bool(enable)::nil);
}

QWidget._setWindowTitle[T](w: T, title: string)
    for { T => _get_proxy: fn(w: self T): string; }
{
    call(w._get_proxy(), "setWindowTitle", enc_str(title)::nil);
}

QWidget._show[T](w: T)
    for { T => _get_proxy: fn(w: self T): string; }
{
    call(w._get_proxy(), "show", nil);
}

QWidget._size[T](w: T): (int, int)
    for { T => _get_proxy: fn(w: self T): string; }
{
    value := call_value(w._get_proxy(), "size", nil, "width"::"height"::nil);
    (width, height) := parse_2tuple(value);
    return (int width, int height);
}

QWidget._update[T](w: T)
    for { T => _get_proxy: fn(w: self T): string; }
{
    call(w._get_proxy(), "update", nil);
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

QWidget.setFixedSize(w: self ref QWidget, width, height: int)
{
    QWidget._setFixedSize(w, width, height);
}

QWidget.setLayout[T](w: self ref QWidget, layout: T)
    for { T => _get_proxy: fn(w: self T): string; }
{
    QWidget._setLayout(w, layout);
}

QWidget.setMouseTracking(w: self ref QWidget, enable: int)
{
    QWidget._setMouseTracking(w, enable);
}

QWidget.setWindowTitle(w: self ref QWidget, title: string)
{
    QWidget._setWindowTitle(w, title);
}

QWidget.show(w: self ref QWidget)
{
    QWidget._show(w);
}

QWidget.size(w: self ref QWidget): (int, int)
{
    return QWidget._size(w);
}

QWidget.update(w: self ref QWidget)
{
    QWidget._update(w);
}
