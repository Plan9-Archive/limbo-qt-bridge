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

implement Widgets;

# Import modules to be used and declare any instances that will be accessed
# globally.

include "sys.m";
    sys: Sys;
    fprint, print, sprint: import sys;

include "draw.m";

include "qtwidgets.m";
    qt: QtWidgets;
    QApplication, QAction, QFileDialog, QMainWindow, QMenu, QMenuBar: import qt;
    connect, Invokable: import qt;

Widgets: module
{
    init: fn(ctxt: ref Draw->Context, args: list of string);
};

# Main function and stream handling functions

app : ref QApplication;
window : ref QMainWindow;

init(ctxt: ref Draw->Context, args: list of string)
{
    # Load instances of modules, one local to init, the other global.
    sys = load Sys Sys->PATH;
    qt = load QtWidgets QtWidgets->PATH;

    qt->init();
    app = QApplication.init(nil);

    window = QMainWindow.init(nil);
    window.resize(800, 600);
    menuBar := window.menuBar();
    menu := menuBar.addMenu("&File");
    openAction := menu.addAction("&Open");
    exitAction := menu.addAction("E&xit");
    connect(openAction, "triggered", handle_open);
    connect(exitAction, "triggered", handle_exit);
    window.setWindowTitle("Limbo to Qt Bridge Demonstration");
    window.show();

    read_ch := qt->get_channels().read_ch;

    for (;;) alt {
        s := <- read_ch =>
            sys->print("unhandled: %s\n", s);
    }
}

handle_exit(args: list of string)
{
    app.quit();
}

handle_open(args: list of string)
{
    value := QFileDialog.getOpenFileName(window, "Open File", "", "*.txt");
    file_name := hd value;
    filter := hd (tl value);
    sys->print("file name: %s, filter: %s\n", file_name, filter);
}
