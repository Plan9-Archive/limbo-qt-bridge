#!/usr/bin/env python3

# process_bridge.py
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

import sys

from PyQt5.QtCore import QSettings, QThread, Qt
from PyQt5.QtGui import QFont
from PyQt5.QtWidgets import QApplication, QTextBrowser

from QtBridge.objectmanager import ObjectManager
from QtBridge.processhandler import ProcessHandler

if __name__ == "__main__":

    app = QApplication(sys.argv)
    
    args = app.arguments()
    if "--debug" in args:
        debug = True
        args.remove("--debug")
    else:
        debug = False
    
    if len(args) != 2:
        sys.stderr.write("Usage: %s <executable>\n" % sys.argv[0])
        sys.exit(1)
    
    executable = app.arguments()[1]
    
    objectManager = ObjectManager(debug = debug)
    
    processThread = QThread()
    processHandler = ProcessHandler(executable)
    processHandler.moveToThread(processThread)
    processThread.started.connect(processHandler.run)
    
    def fn(*args):
        print("Thread finished.")
    
    processThread.finished.connect(fn)
    
    settings = QSettings("uk.org.boddie", "Limbo-Qt bridge")
    geometry = settings.value("log window geometry")
    
    view = QTextBrowser()
    if geometry:
        view.setGeometry(geometry)
    
    if debug:
        view.show()
    
    def html(s):
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
    
    def input_text(s):
        view.append("<i>input: </i><tt>%s</tt>" % html(repr(s)))
    
    def output_text(s):
        view.append("<b>output: </b><tt>%s</tt>\n" % html(repr(s)))
    
    if debug:
        processHandler.commandReceived.connect(input_text)
        objectManager.debugMessage.connect(output_text)
    
    processHandler.commandReceived.connect(objectManager.handleCommand)
    objectManager.messagePending.connect(processHandler.handleOutput)
    
    # Manage application exit carefully by monitoring when the last window is
    # closed. In theory, the process handler and its thread should not have
    # been deleted at this point.
    app.setQuitOnLastWindowClosed(False)
    app.lastWindowClosed.connect(processHandler.quit)
    
    def saveSettingsAndExit():
        settings.setValue("log window geometry", view.geometry())
        print("Thread is running:", processThread.isRunning())
        print("Process state:", processHandler.process.state())
        app.quit()
    
    processHandler.processFinished.connect(objectManager.handleFinished)
    processHandler.processError.connect(objectManager.handleError)
    objectManager.finished.connect(processThread.quit)
    processThread.finished.connect(saveSettingsAndExit)
    
    processThread.start()
    sys.exit(app.exec());
