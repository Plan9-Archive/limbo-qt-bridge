# painting.b
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

implement Painting;

# Import modules to be used and declare any instances that will be accessed
# globally.

include "sys.m";
    sys: Sys;
    fprint, print, sprint: import sys;

include "draw.m";

include "qtwidgets.m";
    qt: QtWidgets;
    QApplication, QColor, QLabel, QPainter, QPixmap, QWidget: import qt;

Painting: module
{
    init: fn(ctxt: ref Draw->Context, args: list of string);
};

# Main function and stream handling functions

init(ctxt: ref Draw->Context, args: list of string)
{
    # Load instances of modules, one local to init, the other global.
    sys = load Sys Sys->PATH;
    qt = load QtWidgets QtWidgets->PATH;

    qt->init();
    app := QApplication.new();

    pixmap := QPixmap.new(400, 400);
    pixmap.fill(QColor(240, 160, 100, 255));

    painter := QPainter.new();
    painter.begin(pixmap);
    painter.drawText(150, 180, "Hello Limbo!");
    painter.end();

    label := QLabel.new();
    label.setPixmap(pixmap);

    QWidget._setWindowTitle(label, "Limbo to Qt Bridge Painting Demonstration");
    QWidget._show(label);

    for (;;) {}
}
