# widgets.b
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

implement Layouts;

# Import modules to be used and declare any instances that will be accessed
# globally.

include "sys.m";
    sys: Sys;
    fprint, print, sprint: import sys;

include "draw.m";

include "qtwidgets.m";
    qt: QtWidgets;
    QApplication, QLabel, QVBoxLayout, QWidget: import qt;

Layouts: module
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

    window := QWidget.new();

    label1 := QLabel.new();
    label1.setText("Hello Limbo!");

    label2 := QLabel.new();
    label2.setText("Hello Qt!");

    layout := QVBoxLayout.new();
    layout.addWidget(label1);
    layout.addWidget(label2);
    window.setLayout(layout);

    window.setWindowTitle("Limbo to Qt Bridge Layouts Demonstration");
    window.resize(640, 480);
    window.show();

    for (;;) {}
}
