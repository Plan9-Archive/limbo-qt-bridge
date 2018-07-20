from PyQt5.QtCore import QByteArray, QObject, QProcess, QThread, pyqtSignal

class ProcessHandler(QObject):

    commandReceived = pyqtSignal(str)
    processFinished = pyqtSignal()
    processError = pyqtSignal(str)
    
    def __init__(self, executable, parent = None):
    
        QObject.__init__(self, parent)
        self.executable = executable
    
    def run(self):
    
        self.process = QProcess(self)
        self.process.readyReadStandardOutput.connect(self.handleInput)
        self.process.finished.connect(self.processFinished)
        self.pendingInput = QByteArray()
        self.pendingOutput = QByteArray()
        self.process.start(self.executable)
        
        # On Qt 5.6 and later, we can use the errorOccurred signal instead.
        if not self.process.waitForStarted(-1):
            self.processError.emit("The application quit unexpectedly.")
    
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
    
    def handleOutput(self, message):
    
        self.pendingOutput += QByteArray(bytes(message, "utf8"))
        
        while self.pendingOutput.size() > 0:
        
            newline = self.pendingOutput.indexOf(b"\n")
            
            if newline == -1:
                return
            
            written = self.process.write(self.pendingOutput.left(newline + 1))
            
            if written == -1:
                self.processError.emit("Failed to write to application.")
                return
            
            # Handle the rest of the output.
            self.pendingOutput = self.pendingOutput.mid(newline + 1)
