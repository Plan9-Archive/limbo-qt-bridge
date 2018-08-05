include "qtchannels.m";
    qtchannels: QtChannels;
    Channels, enc, enc_bool, enc_int, enc_real, enc_str, enc_enum: import qtchannels;
    enc_value, enc_inst, parse_arg, dec_bool, dec_str, dec_int: import qtchannels;
    parse_2tuple, parse_ntuple, parse_args, debug_msg: import qtchannels;

QtWidgets: module
{
    PATH: con "/dis/lib/qtwidgets.dis";

    # Handles communication with the bridge.
    channels : ref Channels;

    # The transaction counter issues single-use identifiers for requests and
    # responses.
    tr_counter : int;

    Invokable: type ref fn(args: list of string);
    EventHandler: type ref fn(proxy: string);

    signal_hash : ref Strhash[list of Invokable];
    event_hash : ref Strhash[EventHandler];

    init: fn();
    get_channels: fn(): ref Channels;

    qdebug: fn(s: string);

    forget: fn[T](obj: T)
        for { T => _get_proxy: fn(w: self T): string; };

    connect: fn[T](src: T, signal: string, slot: Invokable)
        for { T => _get_proxy: fn(w: self T): string; };

    rconnect: fn[T,U](src: T, signal: string, dest: U, slot: string)
        for { T => _get_proxy: fn(w: self T): string;
              U => _get_proxy: fn(w: self U): string; };

    filter_event: fn[T](src: T, event_type: int, handler: EventHandler)
        for { T => _get_proxy: fn(w: self T): string; };

    Qt: adt {
        AlignLeft, AlignRight, AlignHCenter, AlignJustify, AlignAbsolute: con (1 << iota);
        AlignCenter: con 16r84;
        AlignTop, AlignBottom, AlignVCenter, AlignBaseline: con (16r20 << iota);

        Widget, Window: con iota;
        Dialog, Sheet, Drawer, Popup, Tool, ToolTip, SplashScreen, Desktop, SubWindow: con ((iota + 1) * 2);
    };

    QAction: adt {
        proxy: string;
        _get_proxy: fn(w: self ref QAction): string;

        setShortcut: fn(w: self ref QAction, keys: string);
    };

    QApplication: adt {
        proxy: string;
        _get_proxy: fn(a: self ref QApplication): string;

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

    QFont: adt {
        proxy: string;
        _get_proxy: fn(w: self ref QFont): string;

        new: fn(): ref QFont;
        setFamily: fn(w: self ref QFont, family: string);
        setPixelSize: fn(w: self ref QFont, size: int);
        setPointSize: fn(w: self ref QFont, size: real);
    };

    QGraphicsEllipseItem: adt {
        proxy: string;
        _get_proxy: fn(w: self ref QGraphicsEllipseItem): string;

        setBrush: fn(w: self ref QGraphicsEllipseItem, brush: QBrush);
        setPen: fn(w: self ref QGraphicsEllipseItem, pen: QPen);
        setPos: fn(w: self ref QGraphicsEllipseItem, x, y: real);
    };

    QGraphicsLineItem: adt {
        proxy: string;
        _get_proxy: fn(w: self ref QGraphicsLineItem): string;

        setPen: fn(w: self ref QGraphicsLineItem, pen: QPen);
        setPos: fn(w: self ref QGraphicsLineItem, x, y: real);
    };

    QGraphicsRectItem: adt {
        proxy: string;
        _get_proxy: fn(w: self ref QGraphicsRectItem): string;

        setBrush: fn(w: self ref QGraphicsRectItem, brush: QBrush);
        setPen: fn(w: self ref QGraphicsRectItem, pen: QPen);
        setPos: fn(w: self ref QGraphicsRectItem, x, y: real);
    };

    QGraphicsSimpleTextItem: adt {
        proxy: string;
        _get_proxy: fn(w: self ref QGraphicsSimpleTextItem): string;

        setBrush: fn(w: self ref QGraphicsSimpleTextItem, brush: QBrush);
        setFont: fn(w: self ref QGraphicsSimpleTextItem, font: ref QFont);
        setPen: fn(w: self ref QGraphicsSimpleTextItem, pen: QPen);
        setPos: fn(w: self ref QGraphicsSimpleTextItem, x, y: real);
    };

    QGraphicsTextItem: adt {
        proxy: string;
        _get_proxy: fn(w: self ref QGraphicsTextItem): string;

        setBrush: fn(w: self ref QGraphicsTextItem, brush: QBrush);
        setFont: fn(w: self ref QGraphicsTextItem, font: ref QFont);
        setPen: fn(w: self ref QGraphicsTextItem, pen: QPen);
        setPos: fn(w: self ref QGraphicsTextItem, x, y: real);
    };

    QGraphicsScene: adt {
        proxy: string;
        _get_proxy: fn(w: self ref QGraphicsScene): string;

        new: fn(): ref QGraphicsScene;
        addEllipse: fn(w: self ref QGraphicsScene, x, y, width, height: real): ref QGraphicsEllipseItem;
        addLine: fn(w: self ref QGraphicsScene, x1, y1, x2, y2: real): ref QGraphicsLineItem;
        addRect: fn(w: self ref QGraphicsScene, x, y, width, height: real): ref QGraphicsRectItem;
        addSimpleText: fn(w: self ref QGraphicsScene, text: string): ref QGraphicsSimpleTextItem;
        addText: fn(w: self ref QGraphicsScene, text: string): ref QGraphicsTextItem;
    };

    QGraphicsView: adt {
        proxy: string;
        _get_proxy: fn(w: self ref QGraphicsView): string;

        NoDrag, ScrollHandDrag, RubberHandDrag: con iota;

        new: fn(): ref QGraphicsView;
        scale: fn(w: self ref QGraphicsView, sx, sy: real);
        setDragMode: fn(w: self ref QGraphicsView, dragMode: int);
        setRenderHint: fn(w: self ref QGraphicsView, hint: int);
        setScene: fn(w: self ref QGraphicsView, scene: ref QGraphicsScene);
        setSceneRect: fn(w: self ref QGraphicsView, x, y, width, height: real);
        setTransform: fn(w: self ref QGraphicsView, transform: ref QTransform);
        translate: fn(w: self ref QGraphicsView, dx, dy: real);
        viewport: fn(w: self ref QGraphicsView): ref QWidget;
    };

    QGridLayout: adt {
        proxy: string;
        _get_proxy: fn(w: self ref QGridLayout): string;

        new: fn(): ref QGridLayout;
        addWidget: fn[T](w: self ref QGridLayout, widget: T, row, column, rowspan, colspan: int)
            for { T => _get_proxy: fn(w: self T): string; };
        addLayout: fn[T](w: self ref QGridLayout, widget: T, row, column, rowspan, colspan: int)
            for { T => _get_proxy: fn(w: self T): string; };
        setContentsMargins: fn(w: self ref QGridLayout, left, top, right, bottom: int);
        setSpacing: fn(w: self ref QGridLayout, spacing: int);
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
        setContentsMargins: fn(w: self ref QHBoxLayout, left, top, right, bottom: int);
        setSpacing: fn(w: self ref QHBoxLayout, spacing: int);
    };

    QLabel: adt {
        proxy: string;
        _get_proxy: fn(w: self ref QLabel): string;

        new: fn(): ref QLabel;
        resize: fn(w: self ref QLabel, width, height: int);
        setAlignment: fn(w: self ref QLabel, alignment: int);
        setPixmap: fn[T](w: self ref QLabel, pixmap: T)
            for { T => _get_proxy: fn(w: self T): string; };
        setText: fn(w: self ref QLabel, text: string);
        setWindowTitle: fn(w: self ref QLabel, text: string);
        show: fn(w: self ref QLabel);
        size: fn(w: self ref QLabel): (int, int);
    };

    QLineEdit: adt {
        proxy: string;
        _get_proxy: fn(w: self ref QLineEdit): string;

        new: fn(): ref QLineEdit;
        clear: fn(w: self ref QLineEdit);
        text: fn(w: self ref QLineEdit): string;
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

    QMdiArea: adt {
        proxy: string;
        _get_proxy: fn(w: self ref QMdiArea): string;

        new: fn(): ref QMdiArea;
        addSubWindow: fn[T](w: self ref QMdiArea, widget: T, flags: int): ref QMdiSubWindow
            for { T => _get_proxy: fn(w: self T): string; };
    };

    QMdiSubWindow: adt {
        proxy: string;
        _get_proxy: fn(w: self ref QMdiSubWindow): string;
    };

    QMenu: adt {
        proxy: string;

        addAction: fn(w: self ref QMenu, text: string): ref QAction;
    };

    QMenuBar: adt {
        proxy: string;

        addMenu: fn(w: self ref QMenuBar, title: string): ref QMenu;
    };

    QMouseEvent: adt {
        proxy: string;
        Press: con 2;
        Release: con 3;
        Move: con 5;

        button: fn(e: self ref QMouseEvent): int;
        x: fn(e: self ref QMouseEvent): int;
        y: fn(e: self ref QMouseEvent): int;
        type_: fn(e: self ref QMouseEvent): int;
    };

    QPainter: adt {
        proxy: string;
        _get_proxy: fn(w: self ref QPainter): string;
        Antialiasing: con 1;

        new: fn(): ref QPainter;
        begin: fn[T](w: self ref QPainter, device: T)
            for { T => _get_proxy: fn(w: self T): string; };
        drawEllipse: fn(w: self ref QPainter, x1, y1, width, height: int);
        drawLine: fn(w: self ref QPainter, x1, y1, x2, y2: int);
        drawRect: fn(w: self ref QPainter, x, y, width, height: int);
        drawText: fn(w: self ref QPainter, x, y: int, text: string);
        end: fn(w: self ref QPainter);
        setBrush: fn(w: self ref QPainter, brush: QBrush);
        setPen: fn(w: self ref QPainter, pen: QPen);
        setRenderHint: fn(w: self ref QPainter, hint: int);
    };

    QPen: adt {
        color: QColor;
        width: int;
        enc: fn(w: self QPen): string;
    };

    QPixmap: adt {
        proxy: string;
        _get_proxy: fn(w: self ref QPixmap): string;

        new: fn(width, height: int): ref QPixmap;
        fill: fn(w: self ref QPixmap, color: QColor);
        size: fn(w: self ref QPixmap): (int, int);
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

    QResizeEvent: adt {
        proxy: string;
        Type: con 14;

        oldSize: fn(e: self ref QResizeEvent): (int, int);
        size: fn(e: self ref QResizeEvent): (int, int);
    };

    QTextEdit: adt {
        proxy: string;
        _get_proxy: fn(w: self ref QTextEdit): string;

        new: fn(): ref QTextEdit;
        append: fn(w: self ref QTextEdit, text: string);
        isReadOnly: fn(w: self ref QTextEdit): int;
        setText: fn(w: self ref QTextEdit, text: string);
        setReadOnly: fn(w: self ref QTextEdit, enable: int);
    };

    QTransform: adt {
        proxy: string;
        _get_proxy: fn(w: self ref QTransform): string;

        new: fn(): ref QTransform;
    };

    QVBoxLayout: adt {
        proxy: string;
        _get_proxy: fn(w: self ref QVBoxLayout): string;

        new: fn(): ref QVBoxLayout;
        addWidget: fn[T](w: self ref QVBoxLayout, widget: T)
            for { T => _get_proxy: fn(w: self T): string; };
        addLayout: fn[T](w: self ref QVBoxLayout, widget: T)
            for { T => _get_proxy: fn(w: self T): string; };
        setContentsMargins: fn(w: self ref QVBoxLayout, left, top, right, bottom: int);
        setSpacing: fn(w: self ref QVBoxLayout, spacing: int);
    };

    QWheelEvent: adt {
        proxy: string;
        Type: con 31;

        buttons: fn(e: self ref QWheelEvent): int;
        angleDelta: fn(e: self ref QWheelEvent): int;
        x: fn(e: self ref QWheelEvent): int;
        y: fn(e: self ref QWheelEvent): int;
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
        _setFixedSize: fn[T](w: T, width, height: int)
            for { T => _get_proxy: fn(w: self T): string; };
        _setFocusProxy: fn[T,U](w: T, proxy: U)
            for { T => _get_proxy: fn(w: self T): string;
                  U => _get_proxy: fn(w: self U): string; };
        _setLayout: fn[T](w: T, layout: T)
            for { T => _get_proxy: fn(w: self T): string; };
        _setMouseTracking: fn[T](w: T, enable: int)
            for { T => _get_proxy: fn(w: self T): string; };
        _setWindowTitle: fn[T](w: T, title: string)
            for { T => _get_proxy: fn(w: self T): string; };
        _show: fn[T](w: T)
            for { T => _get_proxy: fn(w: self T): string; };
        _size: fn[T](w: T): (int, int)
            for { T => _get_proxy: fn(w: self T): string; };
        _update: fn[T](w: T)
            for { T => _get_proxy: fn(w: self T): string; };

        new: fn(): ref QWidget;
        close: fn(w: self ref QWidget);
        resize: fn(w: self ref QWidget, width, height: int);
        setFixedSize: fn(w: self ref QWidget, width, height: int);
        setMouseTracking: fn(w: self ref QWidget, enable: int);
        setLayout: fn[T](w: self ref QWidget, layout: T)
            for { T => _get_proxy: fn(w: self T): string; };
        setWindowTitle: fn(w: self ref QWidget, title: string);
        show: fn(w: self ref QWidget);
        size: fn(w: self ref QWidget): (int, int);
        update: fn(w: self ref QWidget);
    };
};
