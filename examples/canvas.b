# canvas.b
#
# Written in 2018 by David Boddie <david@boddie.org.uk>
#
# To the extent possible under law, the author(s) have dedicated all copyright
# and related and neighboring rights to this software to the public domain
# worldwide. This software is distributed without any warranty.
#
# You should have received a copy of the CC0 Public Domain Dedication along with
# this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.

# Tests an integration bridge between Limbo and Qt.

implement Canvas;

# Import modules to be used and declare any instances that will be accessed
# globally.

include "draw.m";

include "sys.m";
    sys: Sys;
    fprint, print, sprint: import sys;

include "rand.m";
    rand: Rand;

include "qtwidgets.m";
    qt: QtWidgets;
    QApplication, QBrush, QColor, QFont, QGraphicsEllipseItem: import qt;
    QGraphicsLineItem, QGraphicsRectItem, QGraphicsScene: import qt;
    QGraphicsSimpleTextItem, QGraphicsView, QPainter: import qt;
    QPen, QVBoxLayout, QWheelEvent, QWidget: import qt;
    filter_event, forget: import qt;

Canvas: module
{
    init: fn(ctxt: ref Draw->Context, args: list of string);
};

# Main function

view: ref QGraphicsView;

init(ctxt: ref Draw->Context, args: list of string)
{
    # Load instances of modules, one local to init, the other global.
    sys = load Sys Sys->PATH;
    rand = load Rand Rand->PATH;
    qt = load QtWidgets QtWidgets->PATH;

    qt->init();
    app := QApplication.new();

    window := QWidget.new();
    scene := QGraphicsScene.new();
    view = QGraphicsView.new();
    view.setScene(scene);
    view.setDragMode(QGraphicsView.ScrollHandDrag);
    view.setSceneRect(-400.0, -300.0, 800.0, 600.0);
    view.setRenderHint(QPainter.Antialiasing);

    filter_event(view.viewport(), QWheelEvent.Type, scaleView);

    layout := QVBoxLayout.new();
    layout.setContentsMargins(0, 0, 0, 0);
    layout.addWidget(view);
    window.setLayout(layout);

    window.setWindowTitle("Limbo to Qt Bridge Canvas Demonstration");
    window.resize(800, 600);
    window.show();

    cs: con 1000;

    spawn addEllipses(scene, 800, 600, 5*cs);
    spawn addRects(scene, 800, 600, 3*cs);
    spawn addLines(scene, 800, 600, 1*cs);
    spawn addTexts(scene, 800, 600, 2*cs);
}

addEllipses(scene: ref QGraphicsScene, width, height: int, delay: int)
{
    for (;;) {
        ellipse := scene.addEllipse(randreal(width), randreal(height), 100.0, 100.0);
        ellipse.setBrush(QBrush(randcolour()));

        # The scene takes ownership of the item so we don't need to keep a
        # reference to it.
        forget(ellipse);
        sys->sleep(delay);
    }
}

addRects(scene: ref QGraphicsScene, width, height: int, delay: int)
{
    for (;;) {
        rect := scene.addRect(randreal(width), randreal(height), 100.0, 100.0);
        rect.setBrush(QBrush(randcolour()));

        # The scene takes ownership of the item so we don't need to keep a
        # reference to it.
        forget(rect);
        sys->sleep(delay);
    }
}

addLines(scene: ref QGraphicsScene, width, height: int, delay: int)
{
    for (;;) {
        line := scene.addLine(randreal(width), randreal(height),
                              randreal(width), randreal(height));
        line.setPen(QPen(randcolour(), rand->rand(4)));

        # The scene takes ownership of the item so we don't need to keep a
        # reference to it.
        forget(line);
        sys->sleep(delay);
    }
}

addTexts(scene: ref QGraphicsScene, width, height: int, delay: int)
{
    for (;;) {
        font := QFont.new();
        font.setPixelSize(1 + rand->rand(30));

        item := scene.addSimpleText("Hello Limbo");
        item.setFont(font);
        item.setBrush(QBrush(randcolour()));
        item.setPos(randreal(width), randreal(height));

        # The scene takes ownership of the item so we don't need to keep a
        # reference to it. Also, we don't need to keep the font around.
        forget(item);
        forget(font);
        sys->sleep(delay);
    }
}

scaleView(proxy: string)
{
    event := ref QWheelEvent(proxy);
    step := event.angleDelta()/120;

    if (step > 0)
        view.scale(1.25, 1.25);
    else if (step < 0)
        view.scale(0.8, 0.8);
}

randreal(size: int): real
{
    return (real rand->rand(size)) - (real size)/2.0;
}

randcolour(): QColor
{
    return QColor(rand->rand(255), rand->rand(255), rand->rand(255), rand->rand(255));
}
