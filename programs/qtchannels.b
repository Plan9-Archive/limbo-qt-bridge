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
    tables = load Tables Tables->PATH;
    
    # Enable raw mode so that characters written to stdin are not automatically
    # echoed back to stdout without us seeing them.
    consctl = sys->open("/dev/consctl", sys->OWRITE);
    sys->write(consctl, array of byte "rawon\n", 6);

    response_hash := Table[chan of string].new(7, nil);
    read_ch := chan of string;
    write_ch := chan of string;

    c := ref Channels(0, response_hash, read_ch, write_ch);

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
    
    # Internally, the identifier 0 is reserved for general communication, so
    # use values from 1 to 1024 for other messages.
    c.response_hash.add(c.counter + 1, response_ch);

    return (c.counter + 1, response_ch);
}

Channels.reader(c: self ref Channels)
{
    stdin := sys->fildes(0);
    read_array := array[256] of byte;
    current := "";
    value_str : string;

    for (;;) {

        #sys->print("Reading...\n");
        # Read as much as possible from stdin.
        read := sys->read(stdin, read_array, 256);
        # Convert the input to a string and append it to the current string.
        current += string read_array[:read];
        #sys->print("Read %d bytes\n", read);

        # Split the current text at the first newline, obtaining the next
        # command string.
        (value_str, current) = str->splitstrl(current, "\n");
        #sys->print("'%s' '%s'\n", value_str, current);

        # If there was no newline then put the value string back in the current
        # string and keep reading.
        if (current == nil) {
            current = value_str;
            continue;
        }

        if (len current > 0)
            current = current[1:];

        # The value string does not contain a trailing newline.

        # Remove the first word from the value string ("value"), extract the
        # second (the identifier) and return the rest as a value.
        token : string;
        (token, value_str) = str->splitl(value_str, " ");
        value_str = value_str[1:];

        (token, value_str) = str->splitl(value_str, " ");
        id := int token;
        value_str = value_str[1:];

        ch := c.response_hash.find(id);
        if (ch != nil) {
            ch <-= value_str;
            continue;
        }

        # Send the command via the default read channel.
        c.read_ch <-= value_str;
    }
}

Channels.writer(c: self ref Channels)
{
    stdout := sys->fildes(1);

    for (;;) {

        # Convert each string from the write channel to a byte array.
        s := <- c.write_ch;
        write_array := array of byte s;

        # Write the entire array to stdout.
        available := len write_array;
        if (sys->write(stdout, write_array, available) != available) {
            fprint(sys->fildes(2), "Write error.\n");
            exit;
        }
    }
}

Channels.request(c: self ref Channels, action: string, args: list of string): string
{
    # Obtain a channel to use to receive a response.
    (key, response_ch) := c.get();

    # Send the call request and receive the response.
    message := sprint("%s %d", action, key);
    for (; args != nil; args = tl args)
        message += " " + hd args;

    c.write_ch <-= message + "\n";
    value := <- response_ch;

    # Delete the entry for the response in the response hash.
    c.response_hash.del(key);

    return value;
}
