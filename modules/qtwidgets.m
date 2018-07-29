include "qtchannels.m";
    qtchannels: QtChannels;
    Channels, enc, enc_int, enc_str, enc_enum, enc_value, enc_inst: import qtchannels;
    parse_arg, dec_str, dec_int, parse_2tuple, parse_ntuple: import qtchannels;

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

    debug_msg: fn(s: string);

    connect: fn[T](src: T, signal: string, slot: Invokable)
        for { T => _get_proxy: fn(w: self T): string; };

    dispatcher: fn(signal_ch: chan of string);

    rconnect: fn[T,U](src: T, signal: string, dest: U, slot: string)
        for { T => _get_proxy: fn(w: self T): string;
              U => _get_proxy: fn(w: self U): string; };

    Qt: adt {
        AlignLeft, AlignRight, AlignHCenter, AlignJustify, AlignAbsolute: con (1 << iota);
        AlignCenter: con 16r84;
        AlignTop, AlignBottom, AlignVCenter, AlignBaseline: con (16r20 << iota);
    };

    QAction: adt {
        proxy: string;
        _get_proxy: fn(w: self ref QAction): string;
    };

    QApplication: adt {
        proxy: string;

        new: fn(): ref QApplication;
        quit: fn(w: self ref QApplication);
    };

    QBrush: adt {
        color: QColor;
        enc: fn(w: self QBrush): string;
    };

    QCheckBox: adt {
        proxy: string;
        _get_proxy: fn(w: self ref QCheckBox): string;

        new: fn(text: string): ref QCheckBox;
    };

    QColor: adt {
        red, green, blue, alpha: int;
        enc: fn(w: self QColor): string;
    };

    QDialog: adt {
        proxy: string;
        _get_proxy: fn(w: self ref QDialog): string;

        new: fn(): ref QDialog;
        exec: fn(w: self ref QDialog);
        setLayout: fn[T](w: self ref QDialog, layout: T)
            for { T => _get_proxy: fn(w: self T): string; };
        setWindowTitle: fn(w: self ref QDialog, title: string);
        show: fn(w: self ref QDialog);
    };

    QFileDialog: adt {
        proxy: string;

        getOpenFileName: fn[T](parent: T, caption, dir, filter: string): (string, string)
            for { T => _get_proxy: fn(w: self T): string; };
    };

    QGridLayout: adt {
        proxy: string;
        _get_proxy: fn(w: self ref QGridLayout): string;

        new: fn(): ref QGridLayout;
        addWidget: fn[T](w: self ref QGridLayout, widget: T, row, column, rowspan, colspan: int)
            for { T => _get_proxy: fn(w: self T): string; };
        addLayout: fn[T](w: self ref QGridLayout, widget: T, row, column, rowspan, colspan: int)
            for { T => _get_proxy: fn(w: self T): string; };
    };

    QGroupBox: adt {
        proxy: string;
        _get_proxy: fn(w: self ref QGroupBox): string;

        new: fn(title: string): ref QGroupBox;
        setLayout: fn[T](w: self ref QGroupBox, layout: T)
            for { T => _get_proxy: fn(w: self T): string; };
    };

    QHBoxLayout: adt {
        proxy: string;
        _get_proxy: fn(w: self ref QHBoxLayout): string;

        new: fn(): ref QHBoxLayout;
        addWidget: fn[T](w: self ref QHBoxLayout, widget: T)
            for { T => _get_proxy: fn(w: self T): string; };
        addLayout: fn[T](w: self ref QHBoxLayout, widget: T)
            for { T => _get_proxy: fn(w: self T): string; };
    };

    QLabel: adt {
        proxy: string;
        _get_proxy: fn(w: self ref QLabel): string;

        new: fn(): ref QLabel;
        setAlignment: fn(w: self ref QLabel, alignment: int);
        setPixmap: fn[T](w: self ref QLabel, pixmap: T)
            for { T => _get_proxy: fn(w: self T): string; };
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

    QPainter: adt {
        proxy: string;

        new: fn(): ref QPainter;
        begin: fn[T](w: self ref QPainter, device: T)
            for { T => _get_proxy: fn(w: self T): string; };
        drawEllipse: fn(w: self ref QPainter, x1, y1, width, height: int);
        drawLine: fn(w: self ref QPainter, x1, y1, x2, y2: int);
        drawRect: fn(w: self ref QPainter, x, y, width, height: int);
        drawText: fn(w: self ref QPainter, x, y: int, text: string);
        end: fn(w: self ref QPainter);
        setBrush: fn(w: self ref QPainter, brush: QBrush);
        setPen: fn(w: self ref QPainter, brush: QPen);
    };

    QPen: adt {
        color: QColor;
        enc: fn(w: self QPen): string;
    };

    QPixmap: adt {
        proxy: string;
        _get_proxy: fn(w: self ref QPixmap): string;

        new: fn(width, height: int): ref QPixmap;
        fill: fn(w: self ref QPixmap, color: QColor);
    };

    QPushButton: adt {
        proxy: string;
        _get_proxy: fn(w: self ref QPushButton): string;

        new: fn(text: string): ref QPushButton;
    };

    QRadioButton: adt {
        proxy: string;
        _get_proxy: fn(w: self ref QRadioButton): string;

        new: fn(text: string): ref QRadioButton;
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
        _close: fn[T](w: T)
            for { T => _get_proxy: fn(w: self T): string; };
        _resize: fn[T](w: T, width, height: int)
            for { T => _get_proxy: fn(w: self T): string; };
        _setLayout: fn[T](w: T, layout: T)
            for { T => _get_proxy: fn(w: self T): string; };
        _setWindowTitle: fn[T](w: T, title: string)
            for { T => _get_proxy: fn(w: self T): string; };
        _show: fn[T](w: T)
            for { T => _get_proxy: fn(w: self T): string; };
        _size: fn[T](w: T): (int, int)
            for { T => _get_proxy: fn(w: self T): string; };

        new: fn(): ref QWidget;
        close: fn(w: self ref QWidget);
        resize: fn(w: self ref QWidget, width, height: int);
        setLayout: fn[T](w: self ref QWidget, layout: T)
            for { T => _get_proxy: fn(w: self T): string; };
        setWindowTitle: fn(w: self ref QWidget, title: string);
        show: fn(w: self ref QWidget);
        size: fn(w: self ref QWidget): (int, int);
    };
};
