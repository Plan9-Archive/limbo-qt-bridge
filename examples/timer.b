# timer.b
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

implement Timer;

# Import modules to be used and declare any instances that will be accessed
# globally.

include "draw.m";

include "sys.m";
    sys: Sys;
    fprint, print, sprint: import sys;

include "qtwidgets.m";
    qt: QtWidgets;
    QApplication, QLabel, QTimer: import qt;
    connect, forget: import qt;

Timer: module
{
    init: fn(ctxt: ref Draw->Context, args: list of string);
};

init(ctxt: ref Draw->Context, args: list of string)
{
    sys = load Sys Sys->PATH;
    qt = load QtWidgets QtWidgets->PATH;

    qt->init();
    app := QApplication.new();

    label := QLabel.new();
    timer := QTimer.new();
    spawn time_out(connect(timer, "timeout"), label);
    timer.start(1000);

    label.setText("Limbo to Qt Bridge Timer Demonstration");
    label.show();
}

time_out(ch: chan of list of string, label: ref QLabel)
{
    i := 0;

    for (;;) {
        # Discard the signal arguments.
        <- ch;

        label.setText(string i);
        i++;
    }
}
