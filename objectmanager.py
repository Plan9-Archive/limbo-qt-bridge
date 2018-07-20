from PyQt5.QtCore import QCoreApplication, QObject

class ObjectManager(QObject):

    def __init__(self, parent = None):
    
        QObject.__init__(self, parent)
        
        self.objects = {}
    
    def handleCommand(self, command):
    
        space = command.find(" ")
        if space == -1:
            return
        
        command, args = command[:space], command[space + 1:]
        
        if command == "create":
            print("create")
    
    def handleError(self):
    
        print("Error")
        QCoreApplication.instance().quit()
    
    def handleFinished(self):
    
        print("Finished")
        QCoreApplication.instance().quit()
