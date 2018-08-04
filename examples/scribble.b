# scribble.b
#
# Written in 2018 by David Boddie <david@boddie.org.uk>
# The circlept and timer functions, and parts of the drawClock function were
# originally part of Inferno's appl/wm/clock.b file which is subject to the
# Lucent Public License 1.02.
#
# To the extent possible under law, the author(s) have dedicated all copyright
# and related and neighboring rights to this software to the public domain
# worldwide. This software is distributed without any warranty.
#
# You should have received a copy of the CC0 Public Domain Dedication along with
# this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.

# Tests an integration bridge between Limbo and Qt.

implement Scribble;

# Import modules to be used and declare any instances that will be accessed
# globally.

include "sys.m";
    sys: Sys;
    fprint, print, sprint: import sys;

include "draw.m";

include "math.m";
    math: Math;

include "string.m";
    str: String;

include "daytime.m";
    daytime: Daytime;
    Tm: import daytime;

include "qtwidgets.m";
    qt: QtWidgets;
    QApplication, QBrush, QColor, QLabel, QMouseEvent, QPainter: import qt;
    QPen, QPixmap, QResizeEvent, QWidget, forget, filter_event, qdebug: import qt;

Scribble: module
{
    init: fn(ctxt: ref Draw->Context, args: list of string);
};

# Use an ADT to hold all the parts of the application that need to be accessed
# from different places.

Window: adt {
    label: ref QLabel;
    pixmap: ref QPixmap;
    lock: chan of int;
    x, y: int;

    new: fn(): ref Window;
    mouseMove: fn(proxy: string);
    mousePress: fn(proxy: string);
};

window: ref Window;

# Main function and stream handling functions

init(ctxt: ref Draw->Context, args: list of string)
{
    # Load instances of modules, one local to init, the other global.
    sys = load Sys Sys->PATH;
    str = load String String->PATH;
    qt = load QtWidgets QtWidgets->PATH;

    qt->init();
    app := QApplication.new();

    window = Window.new();
}

Window.new(): ref Window
{
    label := QLabel.new();
    pixmap := QPixmap.new(800, 600);
    lock := chan[1] of int;

    window := Window(label, pixmap, lock, 0, 0);
    pixmap.fill(QColor(255,255,255,255));

    filter_event(label, QMouseEvent.Press, Window.mousePress);
    filter_event(label, QMouseEvent.Move, Window.mouseMove);

    QWidget._setFixedSize(label, 800, 600);
    label.setPixmap(pixmap);
    label.setWindowTitle("Scribble");
    label.show();

    return ref window;
}

Window.mousePress(proxy: string)
{
    event := ref QMouseEvent(proxy);
    x := event.x();
    y := event.y();

    window.lock <-= 1;
    window.x = x;
    window.y = y;
    <- window.lock;
}

Window.mouseMove(proxy: string)
{
    event := ref QMouseEvent(proxy);
    x := event.x();
    y := event.y();
    pixmap := window.pixmap;

    painter := QPainter.new();
    painter.begin(pixmap);
    painter.setRenderHint(QPainter.Antialiasing);

    painter.setPen(QPen(QColor(0, 0, 255, 255), 2));

    window.lock <-= 1;
    painter.drawLine(window.x, window.y, x, y);
    window.x = x;
    window.y = y;
    <- window.lock;

    painter.end();
    window.label.setPixmap(pixmap);
}
