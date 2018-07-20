#!/usr/bin/env python3

import sys

from PyQt5.QtCore import QThread, Qt
from PyQt5.QtWidgets import QApplication, QTextBrowser

from processhandler import ProcessHandler

if __name__ == "__main__":

    app = QApplication(sys.argv)
    
    if len(app.arguments()) != 2:
        sys.stderr.write("Usage: %s <executable>\n" % sys.argv[0])
        sys.exit(1)
    
    executable = app.arguments()[1]
    
    processThread = QThread()
    processHandler = ProcessHandler(executable)
    processHandler.moveToThread(processThread)
    processThread.started.connect(processHandler.run)
    processThread.start()
    
    view = QTextBrowser()
    view.show()
    
    processHandler.commandReceived.connect(view.append)
    
    sys.exit(app.exec());
