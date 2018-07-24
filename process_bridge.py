#!/usr/bin/env python3

import sys

from PyQt5.QtCore import QSettings, QThread, Qt
from PyQt5.QtGui import QFont
from PyQt5.QtWidgets import QApplication, QTextBrowser

from objectmanager import ObjectManager
from processhandler import ProcessHandler

if __name__ == "__main__":

    app = QApplication(sys.argv)
    
    if len(app.arguments()) != 2:
        sys.stderr.write("Usage: %s <executable>\n" % sys.argv[0])
        sys.exit(1)
    
    executable = app.arguments()[1]
    
    objectManager = ObjectManager()
    
    processThread = QThread()
    processHandler = ProcessHandler(executable)
    processHandler.moveToThread(processThread)
    processThread.started.connect(processHandler.run)
    
    settings = QSettings("uk.org.boddie", "Limbo-Qt bridge")
    geometry = settings.value("log window geometry")
    
    view = QTextBrowser()
    if geometry:
        view.setGeometry(geometry)
    
    view.show()
    
    def html(s):
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
    
    def input_text(s):
        view.append("<i>input: </i><tt>%s</tt>" % html(repr(s)))
    
    def output_text(s):
        view.append("<b>output: </b><tt>%s</tt>\n" % html(repr(s)))
    
    processHandler.commandReceived.connect(input_text)
    objectManager.debugMessage.connect(output_text)
    
    processHandler.commandReceived.connect(objectManager.handleCommand)
    processHandler.processFinished.connect(objectManager.handleFinished)
    processHandler.processError.connect(objectManager.handleError)
    objectManager.messagePending.connect(processHandler.handleOutput)
    
    def saveSettings():
        settings.setValue("log window geometry", view.geometry())
    
    # Manage application exit carefully by monitoring when the last window is
    # closed. In theory, the process handler and its thread should not have
    # been deleted at this point.
    app.setQuitOnLastWindowClosed(False)
    app.lastWindowClosed.connect(processHandler.quit)
    app.lastWindowClosed.connect(saveSettings)
    
    processThread.start()
    sys.exit(app.exec());
