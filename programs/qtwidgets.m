include "qtchannels.m";
    qtchannels: QtChannels;
    Channels: import qtchannels;

QtWidgets: module
{
    PATH: con "/dis/lib/qtwidgets.dis";

    channels : ref Channels;

    Widget: adt {
        name: string;

        init: fn(class, name: string, args: list of string): ref Widget;
        call: fn(w: self ref Widget, method: string, args: list of string): string;
    };

    init: fn();
    get_channels: fn(): ref Channels;
};
