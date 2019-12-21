import lib.scope as scope_

class GenernalEvent(scope_.Event):
    def __init__(self, source_name):
        scope_.Event.__init__(self, source_name)
        
