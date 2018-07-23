include "tables.m";
    tables: Tables;
    Strhash, Table: import tables;

QtChannels: module
{
    PATH: con "/dis/lib/qtchannels.dis";

    Channels: adt {
        counter: int;
        response_hash : ref Table[chan of string];
        read_ch : chan of string;
        write_ch : chan of string;

        init: fn(): ref Channels;
        get: fn(c: self ref Channels): (int, chan of string);
        reader: fn(c: self ref Channels);
        writer: fn(c: self ref Channels);
        request: fn(c: self ref Channels, action: string, args: list of string): string;
    };
};
