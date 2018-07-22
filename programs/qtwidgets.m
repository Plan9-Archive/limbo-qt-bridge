include "qtchannels.m";
    qtchannels: QtChannels;
    Channels: import qtchannels;

QtWidgets: module
{
    PATH: con "/dis/lib/qtwidgets.dis";

    channels : ref Channels;
    counter : int;

    init: fn();
    get_channels: fn(): ref Channels;

    Proxy: adt {
        name: string;

        init: fn(class: string, args: list of string): ref Proxy;
        call: fn(w: self ref Proxy, method: string, args: list of string): string;
    };

    QWidget: adt {
        proxy: ref Proxy;

        init: fn(args: list of string): ref QWidget;
        close: fn(w: self ref QWidget);
        show: fn(w: self ref QWidget);
    };
};
