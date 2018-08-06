# workspace.b
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

implement Workspace;

# Import modules to be used and declare any instances that will be accessed
# globally.

include "draw.m";

include "sys.m";
    sys: Sys;
    fprint, print, sprint: import sys;

include "qtwidgets.m";
    qt: QtWidgets;
    QAction, QApplication, QMainWindow, QMdiArea, QMdiSubWindow: import qt;
    QMenu, QMenuBar, Qt: import qt;
    QTextEdit, QVBoxLayout, QWidget: import qt;
    connect, rconnect, forget: import qt;

Workspace: module
{
    init: fn(ctxt: ref Draw->Context, args: list of string);
};

workspace: ref QMdiArea;

init(ctxt: ref Draw->Context, args: list of string)
{
    sys = load Sys Sys->PATH;
    qt = load QtWidgets QtWidgets->PATH;

    qt->init();
    app := QApplication.new();

    window := QMainWindow.new();
    menuBar := window.menuBar();
    
    workspace = QMdiArea.new();

    fileMenu := menuBar.addMenu("&File");
    exitAction := fileMenu.addAction("E&xit");
    exitAction.setShortcut("Ctrl+Q");
    rconnect(exitAction, "triggered", app, "quit");

    windowsMenu := menuBar.addMenu("&Windows");
    newWindowAction := windowsMenu.addAction("&New");
    spawn newWindow(connect(newWindowAction, "triggered"));

    window.setCentralWidget(workspace);

    window.setWindowTitle("Limbo to Qt Bridge Workspace Demonstration");
    window.resize(800, 600);
    window.show();
}

newWindow(ch: chan of list of string)
{
    for (;;) {
        # Discard the signal arguments.
        <- ch;

        editor := QTextEdit.new();
        subWindow := workspace.addSubWindow(editor, Qt.Window);
        QWidget._show(subWindow);

        forget(subWindow);
        forget(editor);
    }
}
