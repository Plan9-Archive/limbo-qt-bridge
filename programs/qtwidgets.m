include "qtchannels.m";
    qtchannels: QtChannels;
    Channels: import qtchannels;

QtWidgets: module
{
    PATH: con "/dis/lib/qtwidgets.dis";

    # Handles communication with the bridge.
    channels : ref Channels;

    # The transaction counter issues single-use identifiers for requests and
    # responses.
    tr_counter : int;

    Invokable: type ref fn(args: list of string);
    signal_hash : ref Strhash[list of Invokable];

    init: fn();
    get_channels: fn(): ref Channels;

    create: fn(class: string, args: list of string): string;
    call: fn(proxy, method: string, args: list of string): string;
    call_keep: fn(proxy, method: string, args: list of string): string;

    connect: fn[T](src: T, signal: string, slot: Invokable)
        for { T => _get_proxy: fn(w: self T):string; };

    dispatcher: fn(signal_ch: chan of string);

    QAction: adt {
        proxy: string;

        _get_proxy: fn(w: self ref QAction): string;
    };

    QApplication: adt {
        proxy: string;

        init: fn(args: list of string): ref QApplication;
        quit: fn(w: self ref QApplication);
        quit_slot: fn(w: ref QApplication, args: list of string);
    };

    QMainWindow: adt {
        proxy: string;

        init: fn(args: list of string): ref QMainWindow;
        close: fn(w: self ref QMainWindow);
        menuBar: fn(w: self ref QMainWindow): ref QMenuBar;
        setTitle: fn(w: self ref QMainWindow, title: string);
        show: fn(w: self ref QMainWindow);
    };

    QMenu: adt {
        proxy: string;

        addAction: fn(w: self ref QMenu, text: string): ref QAction;
    };

    QMenuBar: adt {
        proxy: string;

        addMenu: fn(w: self ref QMenuBar, title: string): ref QMenu;
    };

    QWidget: adt {
        proxy: string;

        init: fn(args: list of string): ref QWidget;
        close: fn(w: self ref QWidget);
        show: fn(w: self ref QWidget);
    };
};
