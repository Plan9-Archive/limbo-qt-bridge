#!/usr/bin/env python3

import sys

from PyQt5.QtCore import QThread, Qt
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
    processThread.finished.connect(processHandler.quit)
    
    view = QTextBrowser()
    view.show()
    
    processHandler.commandReceived.connect(view.append)
    objectManager.debugMessage.connect(view.append)
    objectManager.debugMessage.connect(print)
    
    processHandler.commandReceived.connect(objectManager.handleCommand)
    processHandler.processFinished.connect(objectManager.handleFinished)
    processHandler.processError.connect(objectManager.handleError)
    objectManager.messagePending.connect(processHandler.handleOutput)
    
    # Ensure that the process thread is stopped before exiting.
    app.aboutToQuit.connect(processThread.quit)
    
    processThread.start()
    sys.exit(app.exec());
