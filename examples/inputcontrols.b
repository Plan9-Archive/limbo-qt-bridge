# inputcontrols.b
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

implement InputControls;

# Import modules to be used and declare any instances that will be accessed
# globally.

include "sys.m";
    sys: Sys;
    fprint, print, sprint: import sys;

include "draw.m";

include "string.m";
    str: String;

include "qtwidgets.m";
    qt: QtWidgets;
    QApplication, QCheckBox, QDialog, QGroupBox, QHBoxLayout: import qt;
    QPushButton, QRadioButton, QVBoxLayout, rconnect: import qt;

InputControls: module
{
    init: fn(ctxt: ref Draw->Context, args: list of string);
};

# Main function and stream handling functions

init(ctxt: ref Draw->Context, args: list of string)
{
    # Load instances of modules, one local to init, the other global.
    sys = load Sys Sys->PATH;
    str = load String String->PATH;
    qt = load QtWidgets QtWidgets->PATH;

    qt->init();
    app := QApplication.new();

    window := QDialog.new();

    checkBoxGroup := QGroupBox.new("Technologies");
    checkBoxLayout := QVBoxLayout.new();
    checkBoxLayout.addWidget(QCheckBox.new("Limbo"));
    checkBoxLayout.addWidget(QCheckBox.new("Qt"));
    checkBoxLayout.addWidget(QCheckBox.new("Dis"));
    checkBoxGroup.setLayout(checkBoxLayout);

    radioButtonGroup := QGroupBox.new("Operating Systems");
    radioButtonLayout := QVBoxLayout.new();
    radioButtonLayout.addWidget(QRadioButton.new("Plan 9"));
    radioButtonLayout.addWidget(QRadioButton.new("Inferno"));
    radioButtonLayout.addWidget(QRadioButton.new("Linux"));
    radioButtonLayout.addWidget(QRadioButton.new("Windows"));
    radioButtonGroup.setLayout(radioButtonLayout);

    hbox := QHBoxLayout.new();
    hbox.addWidget(checkBoxGroup);
    hbox.addWidget(radioButtonGroup);

    buttonLayout := QHBoxLayout.new();
    okButton := QPushButton.new("OK");
    buttonLayout.addWidget(okButton);

    rconnect(okButton, "clicked", window, "accept");

    vbox := QVBoxLayout.new();
    vbox.addLayout(hbox);
    vbox.addLayout(buttonLayout);
    window.setLayout(vbox);

    window.setWindowTitle("Limbo to Qt Bridge Input Controls Demonstration");
    window.show();

    read_ch := qt->get_channels().read_ch;

    for (;;) alt {
        s := <- read_ch =>
            sys->print("unhandled: %s\n", s);
    }
}
