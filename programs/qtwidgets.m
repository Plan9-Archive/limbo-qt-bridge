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

    create: fn(class: string, args: list of string): string;
    call: fn(proxy, method: string, args: list of string): string;
    call_keep: fn(proxy, method: string, args: list of string): string;

    QAction: adt {
        proxy: string;
    };

    QApplication: adt {
        proxy: string;

        init: fn(args: list of string): ref QApplication;
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
