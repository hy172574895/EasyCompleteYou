import os
import sys
import logging
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.append(BASE_DIR)
global g_logger
g_logger = logging.getLogger('ECY_server')

# local lib
import goto
import diagnosis
import integration
import completor_manager
import completion
import on_buffer


class EventHandler(object):
    def __init__(self, results_queue):
        self._pass_results_queue = results_queue
        self.buffer_cache = {}
        try:
            self.completion = completion.Operate()
            self.source_manager = completor_manager.Operate()
            self.on_buffer = on_buffer.Operate()
            self.integration = integration.Operate()
            self.diagnosis = diagnosis.Operate()
            self.goto = goto.Operate()
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
        object_ = self.source_manager.GetSourceObjByName(
            source_name, file_type)

        # all the event must return something, if returning None
        # means returning nothing that do not need to send back to vim's side.
        if event_ == 'DoCompletion':
            temp = self.completion.DoCompletion(object_,version_dict,
                    self.buffer_cache)
        elif event_ == 'OnBufferEnter':
            temp = self.on_buffer.OnBufferEnter(object_, version_dict)
            self._update_buffer_cache(version_dict)
        elif event_ == 'Diagnosis':
            temp = self.diagnosis.Diagnosis(object_, version_dict)
        elif event_ == 'Goto':
            temp = self.goto.Goto(object_, version_dict)
        elif event_ == 'integration':
            temp = self.integration.HandleIntegration(object_, version_dict)
        elif event_ == 'InstallSource':
            temp = self.source_manager.InstallSource(
                version_dict['SourcePath'])
            results_.append(temp)
            temp = self.source_manager.GetAvailableSourceForFiletype(file_type)
        results_.append(temp)
        return results_

    def _update_buffer_cache(self, version):
        file_path = version['FilePath']
        buffer_size = 0
        if file_path == '':
            file_path = 'nothing'
        for key, text in self.buffer_cache.items():
            buffer_size += len(text)
        items_list = version['AllTextList']
        if file_path in self.buffer_cache:
            self.buffer_cache[file_path] = items_list
        else:
            if buffer_size < 100000:
                items_list = version['AllTextList']
                self.buffer_cache[file_path] = items_list
