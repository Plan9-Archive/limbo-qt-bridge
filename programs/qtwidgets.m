include "qtchannels.m";
    qtchannels: QtChannels;
    Channels, enc, enc_int, enc_str, parse_arg, dec_str: import qtchannels;
    dec_int, parse_2tuple: import qtchannels;

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

    debug_msg: fn(s: string);

    connect: fn[T](src: T, signal: string, slot: Invokable)
        for { T => _get_proxy: fn(w: self T): string; };

    dispatcher: fn(signal_ch: chan of string);

    QAction: adt {
        proxy: string;
        _get_proxy: fn(w: self ref QAction): string;
    };

    QApplication: adt {
        proxy: string;

        new: fn(): ref QApplication;
        quit: fn(w: self ref QApplication);
    };

    QFileDialog: adt {
        proxy: string;

        getOpenFileName: fn[T](parent: T, caption, dir, filter: string): (string, string)
            for { T => _get_proxy: fn(w: self T): string; };
    };

    QLabel: adt {
        proxy: string;
        _get_proxy: fn(w: self ref QLabel): string;

        new: fn(): ref QLabel;
        setText: fn(w: self ref QLabel, text: string);
    };

    QMainWindow: adt {
        proxy: string;
        _get_proxy: fn(w: self ref QMainWindow): string;

        new: fn(): ref QMainWindow;
        close: fn(w: self ref QMainWindow);
        menuBar: fn(w: self ref QMainWindow): ref QMenuBar;
        resize: fn(w: self ref QMainWindow, width, height: int);
        setCentralWidget: fn[T](w: self ref QMainWindow, widget: T)
            for { T => _get_proxy: fn(w: self T): string; };
        setWindowTitle: fn(w: self ref QMainWindow, title: string);
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

    QTextEdit: adt {
        proxy: string;
        _get_proxy: fn(w: self ref QTextEdit): string;

        new: fn(): ref QTextEdit;
        setText: fn(w: self ref QTextEdit, text: string);
    };

    QVBoxLayout: adt {
        proxy: string;
        _get_proxy: fn(w: self ref QVBoxLayout): string;

        new: fn(): ref QVBoxLayout;
        addWidget: fn[T](w: self ref QVBoxLayout, widget: T)
            for { T => _get_proxy: fn(w: self T): string; };
        addLayout: fn[T](w: self ref QVBoxLayout, widget: T)
            for { T => _get_proxy: fn(w: self T): string; };
    };

    QWidget: adt {
        proxy: string;
        _get_proxy: fn(w: self ref QWidget): string;

        # These methods originate in QWidget, so provide internal convenience
        # functions for calling them.
        _close: fn(proxy: string);
        _resize: fn(proxy: string, width, height: int);
        _setLayout: fn(proxy: string, layout: string);
        _setWindowTitle: fn(proxy, title: string);

        new: fn(): ref QWidget;
        close: fn(w: self ref QWidget);
        resize: fn(w: self ref QWidget, width, height: int);
        setLayout: fn[T](w: self ref QWidget, layout: T)
            for { T => _get_proxy: fn(w: self T): string; };
        setWindowTitle: fn(w: self ref QWidget, title: string);
        show: fn(w: self ref QWidget);
    };
};
