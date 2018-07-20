#!/usr/bin/env python3

import sys

from PyQt5.QtCore import QByteArray, QFile, QObject, QProcess, QThread, Qt, \
                         pyqtSignal, pyqtSlot

from PyQt5.QtWidgets import QApplication, QTextBrowser

class ProcessHandler(QObject):

    commandReceived = pyqtSignal(str)
    
    def __init__(self, executable, parent = None):
    
        QObject.__init__(self, parent)
        self.executable = executable
    
    def run(self):
    
        self.process = QProcess(self)
        self.process.readyReadStandardOutput.connect(self.handleInput)
        self.pendingInput = QByteArray()
        self.process.start(self.executable)
    
    def handleInput(self):
    
        self.pendingInput += self.process.readAllStandardOutput()
        
        while self.pendingInput.size() > 0:
        
            newline = self.pendingInput.indexOf(b"\n")
            if newline == -1:
                return
            
            # Drop the newline from the command.
            command = str(self.pendingInput.left(newline), "utf8")
            # Skip the newline for the rest of the input.
            self.pendingInput = self.pendingInput.mid(newline + 1)
            
            self.commandReceived.emit(command)


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
