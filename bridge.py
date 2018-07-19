#!/usr/bin/env python3

import sys

from PyQt5.QtCore import QByteArray, QFile, QObject, QThread, Qt, pyqtSignal, \
                         pyqtSlot

from PyQt5.QtWidgets import QApplication, QTextBrowser

class StreamHandler(QObject):

    commandReceived = pyqtSignal(str)
    
    def __init__(self, parent = None):
    
        QObject.__init__(self, parent)
    
    def openInput(self):
    
        self.stdin = QFile()
        self.stdin.open(0, QFile.ReadOnly)
    
    def openOutput(self):
    
        self.stdout = QFile()
        self.stdout.open(1, QFile.WriteOnly)
    
    def handleInput(self):
    
        while self.stdin.isOpen():
        
            command = str(self.stdin.readLine(), "utf8")
            if not command:
                break
            
            self.commandReceived.emit(command.strip())
            
            # This shouldn't be needed, but QFile can get into a state where
            # readLine no longer blocks.
        
        print("Input stream closed.")
    
    @pyqtSlot(QByteArray)
    def handleOutput(self, data):
    
        while self.stdout.isOpen() and data.size() > 0:
        
            written = self.stdout.write(data)
            data = data.right(data.size() - written)
    
    @pyqtSlot(str)
    def handleOutput(self, data):
    
        data = QByteArray(bytes(data, "utf8"))
        while self.stdout.isOpen() and data.size() > 0:
        
            written = self.stdout.write(data)
            self.stdout.flush()
            data = data.right(data.size() - written)


if __name__ == "__main__":

    app = QApplication(sys.argv)
    
    inputThread = QThread()
    inputHandler = StreamHandler()
    inputHandler.moveToThread(inputThread)
    # Open stdin after moving the object to the worker thread to avoid creating
    # objects in the GUI thread.
    inputHandler.openInput()
    
    inputThread.started.connect(inputHandler.handleInput)
    inputThread.start()
    
    outputThread = QThread()
    outputHandler = StreamHandler()
    outputHandler.moveToThread(outputThread)
    outputHandler.openOutput()
    outputThread.start()
    
    view = QTextBrowser()
    view.show()
    
    inputHandler.commandReceived.connect(view.append)
    inputHandler.commandReceived.connect(outputHandler.handleOutput)
    
    sys.exit(app.exec());
