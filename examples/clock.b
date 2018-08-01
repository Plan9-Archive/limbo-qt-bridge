# clock.b
#
# Written in 2018 by David Boddie <david@boddie.org.uk>
#
# To the extent possible under law, the author(s) have dedicated all copyright
# and related and neighboring rights to this software to the public domain
# worldwide. This software is distributed without any warranty.
#
# You should have received a copy of the CC0 Public Domain Dedication along with
# this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.

# Tests an integration bridge between Limbo and Qt.

implement Clock;

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
    QApplication, QBrush, QColor, QLabel, QPainter, QPen, QPixmap: import qt;
    QResizeEvent, QWidget, destroy, filter_event, qdebug: import qt;

Clock: module
{
    init: fn(ctxt: ref Draw->Context, args: list of string);
};

pixmap: ref QPixmap;
window: ref QLabel;
lock: chan of int;

# Main function and stream handling functions

init(ctxt: ref Draw->Context, args: list of string)
{
    # Load instances of modules, one local to init, the other global.
    sys = load Sys Sys->PATH;
    str = load String String->PATH;
    math = load Math Math->PATH;
    daytime = load Daytime Daytime->PATH;
    qt = load QtWidgets QtWidgets->PATH;

    lock = chan[1] of int;

    qt->init();
    app := QApplication.new();

    window = QLabel.new();
    pixmap = QPixmap.new(100, 100);

    filter_event(window, QResizeEvent.Type, resizeEvent);

    window.resize(100, 100);
    window.setWindowTitle("Clock");
    window.show();

    now := daytime->now();

    ticks := chan of int;
    spawn timer(ticks, 1000);

    for (;;) alt {
        <- ticks =>
            t := daytime->now();
            if (t != now) {
                now = t;
                drawClock(now);
            }
    }
}

resizeEvent(proxy: string)
{
    event := ref QResizeEvent(proxy);
    (w, h) := event.size();
    (pw, ph) := pixmap.size();

    if (w != pw || h != ph) {
        # Acquire the lock in order to destroy the pixmap.
        lock <-= 1;
        destroy(pixmap);
        pixmap = QPixmap.new(w, h);
        <- lock;
    }

    drawClock(daytime->now());
}

drawClock(t: int)
{
    # Acquire the lock to prevent the pixmap from being deleted while we are
    # painting on it.
    lock <-= 1;

    tms := daytime->local(t);
    anghr := 90 - (tms.hour*5 + tms.min/10) * 6;
    angmin := 90 - tms.min * 6;
    angsec := 90 - tms.sec * 6;
    
    (w, h) := pixmap.size();
    (cx, cy) := (w/2, h/2);

    if (w < h)
        rad := w;
    else
        rad = h;

    rad /= 2;
    rad = int(real rad * 0.9);
    dot_r := rad/20;

    pixmap.fill(QColor(255,255,255,255));

    painter := QPainter.new();
    painter.begin(pixmap);
    painter.setRenderHint(QPainter.Antialiasing);

    painter.setBrush(QBrush(QColor(0,0,255,255)));
    painter.setPen(QPen(QColor(0,0,255,255), 2));

    for (i := 0; i < 12; i++) {
        (x, y) := circlept(cx, cy, rad, i*(360/12));
        painter.drawEllipse(x - dot_r/2, y - dot_r/2, dot_r, dot_r);
    }

    (x, y) := circlept(cx, cy, (rad*3)/4, angmin);
    painter.setPen(QPen(QColor(0,0,128,255), dot_r));
    painter.drawLine(cx, cy, x, y);

    (x, y) = circlept(cx, cy, rad/2, anghr);
    painter.setPen(QPen(QColor(0,64,255,255), dot_r));
    painter.drawLine(cx, cy, x, y);

    (x, y) = circlept(cx, cy, (rad*7/8), angsec);
    painter.setPen(QPen(QColor(0,128,0,255), dot_r/2));
    painter.drawLine(cx, cy, x, y);
    painter.end();

    window.setPixmap(pixmap);

    <- lock;
}

circlept(cx, cy: int, r: int, degrees: int): (int, int)
{
    rad := real degrees * Math->Pi/180.0;
    cx += int (math->cos(rad)*real r);
    cy -= int (math->sin(rad)*real r);
    return (cx, cy);
}

timer(c: chan of int, ms: int)
{
    for (;;) {
        sys->sleep(ms);
        c <-= 1;
    }
}
