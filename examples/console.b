# console.b
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

implement Console;

# Import modules to be used and declare any instances that will be accessed
# globally.

include "sys.m";
    sys: Sys;
    fprint, print, sprint: import sys;

include "draw.m";

include "string.m";
    str: String;

include "sh.m";
    sh: Sh;
    Context, Listnode: import sh;

include "qtwidgets.m";
    qt: QtWidgets;
    QApplication, QLineEdit, QTextEdit, QVBoxLayout, QWidget, connect: import qt;

Console: module
{
    init: fn(ctxt: ref Draw->Context, args: list of string);
};

inputEdit: ref QLineEdit;
outputEdit: ref QTextEdit;
drawctx: ref Draw->Context;

init(ctxt: ref Draw->Context, args: list of string)
{
    # Load instances of modules, one local to init, the other global.
    sys = load Sys Sys->PATH;
    str = load String String->PATH;
    sh = load Sh Sh->PATH;
    qt = load QtWidgets QtWidgets->PATH;

    drawctx = ctxt;

    qt->init();
    app := QApplication.new();

    window := QWidget.new();
    outputEdit = QTextEdit.new();
    outputEdit.setReadOnly(1);
    inputEdit = QLineEdit.new();
    QWidget._setFocusProxy(outputEdit, inputEdit);

    connect(inputEdit, "returnPressed", handleInput);

    layout := QVBoxLayout.new();
    layout.setContentsMargins(0, 0, 0, 0);
    layout.setSpacing(0);
    layout.addWidget(outputEdit);
    layout.addWidget(inputEdit);
    window.setLayout(layout);

    window.setWindowTitle("Console");
    window.show();
}

handleInput(args: list of string)
{
    text := inputEdit.text();
    outputEdit.append(text);
    inputEdit.clear();

    outputEdit.append(sh->system(drawctx, text));
}
