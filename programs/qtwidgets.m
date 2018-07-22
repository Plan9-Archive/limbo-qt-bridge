include "qtchannels.m";
    qtchannels: QtChannels;
    Channels: import qtchannels;

QtWidgets: module
{
    PATH: con "/dis/lib/qtwidgets.dis";

    channels : ref Channels;
    counter : int;

    Widget: adt {
        name: string;

        init: fn(class: string, args: list of string): ref Widget;
        call: fn(w: self ref Widget, method: string, args: list of string): string;

        close: fn(w: self ref Widget);
        show: fn(w: self ref Widget);
    };

    init: fn();
    get_channels: fn(): ref Channels;
};
