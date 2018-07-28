# processhandler.py
#
# Copyright (c) 2018, David Boddie <david@boddie.org.uk>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.

from PyQt5.QtCore import QCoreApplication, QByteArray, QObject, QProcess, \
                         QThread, pyqtSignal

class ProcessHandler(QObject):

    commandReceived = pyqtSignal(str)
    processFinished = pyqtSignal()
    processError = pyqtSignal(str)
    
    def __init__(self, executable, parent = None):
    
        QObject.__init__(self, parent)
        self.executable = executable
    
    def run(self):
    
        self.process = QProcess()
        self.process.readyReadStandardOutput.connect(self.handleInput)
        self.process.setReadChannel(QProcess.StandardOutput)
        self.process.closeReadChannel(QProcess.StandardError)
        self.process.finished.connect(self.processFinished)
        self.pendingInput = QByteArray()
        self.in_message = False
        self.inputExpected = 0
        self.pendingOutput = QByteArray()
        self.process.start(self.executable)
        
        # On Qt 5.6 and later, we can use the errorOccurred signal instead.
        if not self.process.waitForStarted(-1):
            self.processError.emit("The application quit unexpectedly.")
    
    def quit(self):
    
        print("Terminating %i" % self.process.processId())
        self.process.closeReadChannel(QProcess.StandardOutput)
        self.process.closeReadChannel(QProcess.StandardError)
        self.process.closeWriteChannel()
        self.process.terminate()
        self.process.waitForFinished()
        self.thread().quit()
    
    def handleInput(self):
    
        self.pendingInput += self.process.readAllStandardOutput()
        
        try:
            while self.pendingInput.size() > 0:
            
                if not self.in_message:
                    space = self.pendingInput.indexOf(b" ")
                    if space == -1:
                        return
                    
                    # Specify UTF-8 instead of falling back on something implicit.
                    self.inputExpected = int(str(self.pendingInput.left(space), "utf8"))
                    
                    # Examine the rest of the input.
                    self.pendingInput = self.pendingInput.mid(space + 1)
                    self.in_message = True
                
                # Try to read the rest of the message.
                if len(self.pendingInput) >= self.inputExpected:
                
                    command = self.pendingInput.left(self.inputExpected)
                    
                    self.pendingInput = self.pendingInput.mid(self.inputExpected)
                    self.in_message = False
                    self.inputExpected = 0
                    self.commandReceived.emit(str(command, "utf8"))
                
                elif self.process.bytesAvailable() > 0:
                    self.pendingInput += self.process.readAllStandardOutput()
                else:
                    return
        
        except ValueError:
            self.processError.emit(str(self.pendingInput, "utf8"))
    
    def handleOutput(self, message):
    
        # Write the length of the message and the message itself.
        message = "%i %s" % (len(message), message)
        self.pendingOutput += QByteArray(bytes(message, "utf8"))
        
        while self.pendingOutput.size() > 0:
        
            written = self.process.write(self.pendingOutput)
            
            if written == -1:
                self.processError.emit("Failed to write to application.")
                return
            
            # Handle the rest of the output.
            self.pendingOutput = self.pendingOutput.mid(written)
