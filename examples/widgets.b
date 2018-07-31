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

include "string.m";
    str: String;

include "qtwidgets.m";
    qt: QtWidgets;
    QApplication, QAction, QFileDialog, QMainWindow, QMenu, QMenuBar: import qt;
    QTextEdit, connect, Invokable: import qt;

Widgets: module
{
    init: fn(ctxt: ref Draw->Context, args: list of string);
};

# Main function and stream handling functions

app : ref QApplication;
window : ref QMainWindow;
editor : ref QTextEdit;

init(ctxt: ref Draw->Context, args: list of string)
{
    # Load instances of modules, one local to init, the other global.
    sys = load Sys Sys->PATH;
    str = load String String->PATH;
    qt = load QtWidgets QtWidgets->PATH;

    qt->init();
    app = QApplication.new();

    window = QMainWindow.new();

    menuBar := window.menuBar();
    menu := menuBar.addMenu("&File");
    openAction := menu.addAction("&Open");
    exitAction := menu.addAction("E&xit");
    connect(openAction, "triggered", handle_open);
    connect(exitAction, "triggered", handle_exit);

    editor = QTextEdit.new();
    window.setCentralWidget(editor);

    window.setWindowTitle("Limbo to Qt Bridge Demonstration");
    window.resize(800, 600);
    window.show();

    read_ch := qt->get_channels().read_ch;

    for (;;) alt {
        s := <- read_ch =>
            sys->print("unhandled: %s\n", s);
    }
}

handle_exit(args: list of string)
{
    window.close();
}

handle_open(args: list of string)
{
    (file_name, filter) := QFileDialog.getOpenFileName(
        window, "Open File", "", "*.txt");

    if (file_name == nil)
        return;

    (nil, file_name) = str->splitstrr(file_name, "/");

    f := sys->open(file_name, sys->OREAD);
    if (f == nil)
        return;

    s := "";
    b := array[1024] of byte;
    n : int;
    do {
        n = sys->readn(f, b, 1024);
        s += string b[:n];
    } while (n > 0);

    editor.setText(s);
    window.setWindowTitle(file_name + " - Limbo to Qt Bridge Demonstration");
}
