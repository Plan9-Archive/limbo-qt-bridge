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

    enc: fn(s, t: string): string;
    enc_str: fn(s: string): string;
    enc_int: fn(i: int): string;
    enc_enum: fn(name: string, value: int): string;
    enc_value: fn(name: string, values: list of string): string;
    enc_inst: fn[T](instance: T): string
        for { T => _get_proxy: fn(w: self T): string; };
    parse_arg: fn(s: string): (string, string, string);
    dec_str: fn(s: string): string;
    dec_int: fn(s: string): int;
    parse_2tuple: fn(s: string): (string, string);
};
