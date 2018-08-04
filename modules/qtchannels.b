# qtchannels.b
#
# Copyright (c) 2018, David Boddie <david@boddie.org.uk>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.

implement QtChannels;

include "lists.m";
    lists: Lists;

include "string.m";
    str: String;

include "sys.m";
    sys: Sys;
    fprint, print, sprint: import sys;

include "qtchannels.m";

consctl : ref sys->FD;

Channels.init(): ref Channels
{
    sys = load Sys Sys->PATH;
    str = load String String->PATH;
    lists = load Lists Lists->PATH;
    tables = load Tables Tables->PATH;
    
    # Enable raw mode so that characters written to stdin are not automatically
    # echoed back to stdout without us seeing them.
    consctl = sys->open("/dev/consctl", sys->OWRITE);
    sys->write(consctl, array of byte "rawon\n", 6);

    response_hash := Table[chan of string].new(7, nil);
    read_ch := chan of string;
    write_ch := chan of string;

    c := ref Channels(0, 0, response_hash, read_ch, write_ch);

    # Spawn a reader and a writer to handle input and output in the background.
    spawn c.reader();
    spawn c.writer();

    return c;
}

Channels.get(c: self ref Channels): (int, chan of string)
{
    # Creates a new channel and registers it in the hash table.
    response_ch := chan of string;

    c.counter = (c.counter + 1) % 1024;
    c.response_hash.add(c.counter, response_ch);

    return (c.counter, response_ch);
}

Channels.get_persistent(c: self ref Channels): (int, chan of string)
{
    # Creates a new channel and registers it in the hash table.
    response_ch := chan of string;

    c.persistent_counter = (c.persistent_counter + 1) % 1024;
    c.response_hash.add(1024 + c.persistent_counter, response_ch);

    return (1024 + c.persistent_counter, response_ch);
}

Channels.reader(c: self ref Channels)
{
    stdin := sys->fildes(0);
    read_array := array[256] of byte;
    current := "";
    value_str : string;
    in_message := 0;
    input_expected := 0;
    f := sys->create("tmp.txt", sys->OWRITE, 8r666);

    for (;;) {

        # Read as much as possible from stdin.
        read := sys->read(stdin, read_array, 256);

        if (read == 0) {
            debug_msg("Application's stdin closed.");
            exit;
        }

        # Convert the input to a string and append it to the current string.
        current += string read_array[:read];

        # Handle multiple commands while there .
        while (len current >= input_expected) {

            if (in_message == 0) {

                # Find a number followed by a space.
                (length, rest) := str->splitstrl(current, " ");

                # If no space is found then read again.
                if (rest == nil)
                    break;

                # Convert the length string to a number.
                input_expected = int length;

                # Examine the rest of the input.
                current = rest[1:];
                in_message = 1;
            }

            # Try to read the rest of the message.
            if (len current >= input_expected) {

                value_str := current[:input_expected];
                sys->write(f, array of byte (value_str + "\n"), len value_str + 1);
                type_, token : string;

                (type_, token, value_str) = parse_arg(value_str);
                if (type_ != "s") {
                    errstr := sprint("Read error: '%s' '%s' '%s'\n", type_, token, value_str);
                    fprint(sys->fildes(2), "%d %s", len errstr, errstr);
                    exit;
                }

                (type_, token, value_str) = parse_arg(value_str);
                if (type_ != "i") {
                    errstr := sprint("Read error: '%s' '%s' '%s'\n", type_, token, value_str);
                    fprint(sys->fildes(2), "%d %s", len errstr, errstr);
                    exit;
                }

                ch := c.response_hash.find(int token);
                if (ch != nil) {
                    # Send the command via the response channel.
                    ch <-= value_str;
                } else {
                    # Send the command via the default read channel.
                    c.read_ch <-= value_str;
                }

                current = current[input_expected:];
                in_message = 0;
                input_expected = 0;

            } else {
                # Not enough data for the message body so read again.
                break;
            }
        }
    }
}

Channels.writer(c: self ref Channels)
{
    stdout := sys->fildes(1);

    for (;;) {

        # Convert each string from the write channel to a byte array.
        s := <- c.write_ch;
        message_array := array of byte s;
        message_length := len message_array;

        # Prefix the message with its length and append a newline to it.
        length_array := array of byte (string message_length + " ");
        length_length := len length_array;

        # Write the length and space to stdout.
        if (sys->write(stdout, length_array, length_length) != length_length) {
            fprint(sys->fildes(2), "Write error.\n");
            exit;
        }

        # Write the message to stdout.
        if (sys->write(stdout, message_array, message_length) != message_length) {
            fprint(sys->fildes(2), "Write error.\n");
            exit;
        }
    }
}

Channels.request(c: self ref Channels, action: string, args: list of string,
                 return_value_expected: int): string
{
    # Obtain a channel to use to receive a response.
    (id_, response_ch) := c.get();

    # Send the call request and receive the response.
    message := sprint("%s%s", action, enc_int(id_));
    for (; args != nil; args = tl args)
        message += hd args;

    if (message[len message - 1] == ' ')
        message[len message - 1] = '\n';

    c.write_ch <-= message;

    value: string;
    if (return_value_expected)
        value = <- response_ch;
    else
        value = nil;

    # Delete the entry for the response in the response hash.
    c.response_hash.del(id_);

    return value;
}

enc(s, t: string): string
{
    return t + (string len s) + " " + s + " ";
}

enc_str(s: string): string
{
    return enc(s, "s");
}

enc_int(i: int): string
{
    s := string i;
    return enc(s, "i");
}

enc_real(r: real): string
{
    s := string r;
    return enc(s, "f");
}

enc_bool(i: int): string
{
    if (i != 0)
        return enc("True", "B");
    else
        return enc("False", "B");
}

enc_enum(name: string, value: int): string
{
    # Create a pair of encoded values: C<length> <name> i<length> <value>
    s := enc(name, "C") + enc_int(value);
    # Wrap them in an enum value specifier: e<length> ...
    return sprint("v%d %s ", len s, s);
}

enc_value(name: string, values: list of string): string
{
    # Wrap the encoded values in a value class specifier: v<length> ...
    s := enc(name, "C");
    for (; values != nil; values = tl values)
        s += hd values;
    return sprint("v%d %s ", len s, s);
}

enc_inst[T](instance: T): string
    for { T => _get_proxy: fn(w: self T): string; }
{
    return enc(instance._get_proxy(), "I");
}

parse_arg(s: string): (string, string, string)
{
    # Obtain the type and length.
    type_ := s[:1];
    token : string;

    (token, s) = str->splitstrl(s[1:], " ");
    length := int token;

    # Return the type, argument and remaining string.
    token = s[1:1 + length];
    return (type_, token, s[length + 2:]);
}

dec_str(s: string): string
{
    (type_, token, rest) := parse_arg(s);
    return token;
}

dec_int(s: string): int
{
    (type_, token, rest) := parse_arg(s);
    return int token;
}

dec_bool(s: string): int
{
    (type_, token, rest) := parse_arg(s);
    if (token == "True")
        return 1;
    else
        return 0;
}

parse_2tuple(s: string): (string, string)
{
    type_, contents, token0, token1: string;
    (type_, contents, s) = parse_arg(s);
    (type_, token0, contents) = parse_arg(contents);
    (type_, token1, contents) = parse_arg(contents);
    return (token0, token1);
}

parse_ntuple(s: string): list of string
{
    type_, contents, token: string;

    (type_, contents, s) = parse_arg(s);
    return parse_args(contents);
}

parse_args(s: string): list of string
{
    l: list of string;
    type_, token: string;

    while (s != nil) {
        (type_, token, s) = parse_arg(s);
        l = token::l;
    }
    return lists->reverse(l);
}

debug_msg(s: string)
{
    msg := sprint("s5 debug i4 9999 s%d '%s'", len s + 2, s);
    sys->print("%d %s", len msg, msg);
}
