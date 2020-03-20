import os
import sys
import logging
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.append(BASE_DIR)
global g_logger
g_logger = logging.getLogger('ECY_server')

# local lib
import goto
import integration
import completor_manager
import completion
import on_buffer
import document_help


class EventHandler(object):
    def __init__(self, results_queue):
        self._pass_results_queue = results_queue
        try:
            self.completion = completion.Operate()
            self.source_manager = completor_manager.Operate()
            self.on_buffer = on_buffer.Operate()
            self.integration = integration.Operate()
            self.goto = goto.Operate()
            self.document_help = document_help.Operate()
        except:
            g_logger.exception("")
            raise

    def HandleIt(self, version_dict):
        # the following key is needed all the way.
        version_dict = version_dict['Msg']
        event_ = version_dict['Event']
        file_type = version_dict['FileType']
        source_name = version_dict['SourceName']

        results_ = []
        temp = None
        # all the request must choose a source, when it's omit, we will give it
        # one
        if event_ == 'GetAvailableSources':
            temp = self.source_manager.GetAvailableSourceForFiletype(file_type)
            results_.append(temp)
            return results_

        # we passing that queue to let source handle asyn by itself.
        # if the source's event will block for a while, the source can return
        # None, and then put the result into deamon_queue when it finished
        version_dict['DeamonQueue'] = self._pass_results_queue
        engine_obj = self.source_manager.GetSourceObjByName(
            source_name, file_type)

        # all the event must return something, if returning None
        # means returning nothing that do not need to send back to vim's side.
        if event_ == 'DoCompletion':
            version_dict['IsInsertMode'] = True
            temp = self.on_buffer.OnBufferTextChanged(engine_obj, version_dict)
            temp = self.completion.DoCompletion(engine_obj,version_dict)
        elif event_ == 'OnBufferEnter':
            temp = self.on_buffer.OnBufferEnter(engine_obj, version_dict)
            self.completion.UpdateBufferCache(version_dict)
        elif event_ == 'OnInsertModeLeave':
            temp = self.on_buffer.OnInsertModeLeave(engine_obj, version_dict)
        elif event_ == 'OnBufferTextChanged':
            version_dict['IsInsertMode'] = False
            temp = self.on_buffer.OnBufferTextChanged(engine_obj, version_dict)
        elif event_ == 'Goto':
            temp = self.goto.Goto(engine_obj, version_dict)
        elif event_ == 'Integration':
            temp = self.integration.HandleIntegration(engine_obj, version_dict)
        elif event_ == 'GetAllEngineInfo':
            temp = self.source_manager.GetAllEngine(version_dict)
        elif event_ == 'OnDocumentHelp':
            temp = self.document_help.GetDocument(engine_obj, version_dict)
        elif event_ == 'InstallSource':
            temp = self.source_manager.InstallSource(version_dict['EngineName'],
                    version_dict['EngineLib'],
                    package_path=version_dict['EnginePath'])
            results_.append(temp)
            temp = self.source_manager.GetAvailableSourceForFiletype(file_type)
        results_.append(temp)
        return results_
