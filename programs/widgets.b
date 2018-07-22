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

include "qtchannels.m";
    qt: QtChannels;
    Channels: import qt;

Widgets: module
{
    init: fn(ctxt: ref Draw->Context, args: list of string);
};

# Define an data type to represent a widget.

Widget: adt {
    name: string;

    init: fn(class, name: string, args: list of string): ref Widget;
    call: fn(w: self ref Widget, method: string, args: list of string): string;
};

Widget.init(name, class: string, args: list of string): ref Widget
{
    channels.request("create", name, class, args);
    return ref Widget(name);
}

Widget.call(w: self ref Widget, method: string, args: list of string): string
{
    return channels.request("call", w.name, method, args);
}

channels : ref Channels;

# Main function and stream handling functions

init(ctxt: ref Draw->Context, args: list of string)
{
    # Load instances of modules, one local to init, the other global.
    sys = load Sys Sys->PATH;
    qt = load QtChannels "/dis/lib/qtchannels.dis";

    channels = Channels.init();

    widget := Widget.init("window", "QLabel", nil);
    widget.call("setText", "\"Hello world!\""::nil);
    widget.call("show", nil);
    width := int widget.call("width", nil);
    height := int widget.call("height", nil);
    w := sprint("%d", width * 2);
    h := sprint("%d", height * 4);
    widget.call("resize", list of {w, h});

    for (;;) alt {
        s := <- channels.read_ch =>
            ; #sys->print("default: %s\n", s);
    }
}
