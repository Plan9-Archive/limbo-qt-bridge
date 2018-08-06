# console.b
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

include "diskblocks.m";
    diskblocks: Diskblocks;

include "qtwidgets.m";
    qt: QtWidgets;
    QApplication, QLineEdit, QTextEdit, QVBoxLayout, QWidget, connect: import qt;
    qdebug: import qt;

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
    diskblocks = load Diskblocks Diskblocks->PATH;
    qt = load QtWidgets QtWidgets->PATH;

    drawctx = ctxt;
    diskblocks->init();
    qt->init();
    app := QApplication.new();

    window := QWidget.new();
    outputEdit = QTextEdit.new();
    outputEdit.setReadOnly(1);
    inputEdit = QLineEdit.new();
    QWidget._setFocusProxy(outputEdit, inputEdit);

    spawn handleInput(connect(inputEdit, "returnPressed"));

    layout := QVBoxLayout.new();
    layout.setContentsMargins(0, 0, 0, 0);
    layout.setSpacing(0);
    layout.addWidget(outputEdit);
    layout.addWidget(inputEdit);
    window.setLayout(layout);

    window.setWindowTitle("Console");
    window.show();
}

handleInput(ch: chan of list of string)
{
    for (;;) {
        # Discard the signal arguments.
        <- ch;

        text := inputEdit.text();
        outputEdit.append(text);
        inputEdit.clear();

        #temp := diskblocks->tempfile();
        temp := sys->open("/tmp/wdir/appname", sys->OREAD);
        f1 := sys->dup(sys->fildes(1).fd, temp.fd);
        qdebug(sprint("%d\n", f1));

        ch := chan of int;
        spawn runCommand(text, ch, f1);

        a := array[256] of byte;
        output := "";

        for (;;) {
            n := sys->read(temp, a, 256);
            qdebug(sprint("%d\n", n));
            if (n <= 0)
                break;
            output += string a[:n];
        }

        outputEdit.append(output);
    }
}

runCommand(text: string, ch: chan of int, f1: int)
{
    sys->pctl(sys->NEWFD, list of {f1});

    sh->system(drawctx, text);
    ch <-= 1;
}
