import os
import sys
import copy
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
        self._buffer_cache = {}
        self._is_debug = False
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
        engine_name = version_dict['SourceName']
        self._is_debug = version_dict['IsDebugging']

        results_ = []
        temp = None
        # all the request must choose a source, when it's omit, we will give it
        # one
        if event_ == 'GetAvailableSources':
            temp = self.source_manager.GetAvailableSourceForFiletype(file_type)
            results_.append(temp)
            return results_

        if event_ == 'Restart':
            temp = self.source_manager.ReLoadEngine(engine_name)
            results_.append(temp)
            return results_

        # we passing that queue to let source handle asyn by itself.
        # if the source's event will block for a while, the source can return
        # None, and then put the result into deamon_queue when it finished
        version_dict['DeamonQueue'] = self._pass_results_queue
        engine_obj = self.source_manager.GetSourceObjByName(
            engine_name, file_type)

        lists = self.BufferHanlder(version_dict)
        if lists is None:
            return results_
        version_dict['AllTextList'] = "\n".join(lists)

        # all the event must return something, if returning None
        # means returning nothing that do not need to send back to vim's side.
        if event_ == 'DoCompletion':
            version_dict['IsInsertMode'] = True
            # make sure we update text before completing.
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

    def ApplyDiffer(self, commands):
        for buffer_path in commands:
            if buffer_path not in self._buffer_cache:
                continue
            # g_logger.debug("original:"+ str(self._buffer_cache[buffer_path]))
            for item in commands[buffer_path]:
                index = item['line']
                kind = item['kind']
                if kind == 'delete':
                    del self._buffer_cache[buffer_path][index]
                if kind == 'insert':
                    self._buffer_cache[buffer_path].insert(index, item['newtext'])
                if kind == 'replace':
                    if index == 0 and self._buffer_cache[buffer_path] == []:
                        self._buffer_cache[buffer_path] = ['']
                    self._buffer_cache[buffer_path][index] = item['newtext']
                # g_logger.debug("setp:"+ str(self._buffer_cache[buffer_path]))

    def OutputCachedBuffer(self, delete_buffer_path=None):
        """ send to the client
        """
        if delete_buffer_path is not None:
            if delete_buffer_path in self._buffer_cache:
                self._buffer_cache.pop(delete_buffer_path)
        buffer_lists = []
        for file_path in self._buffer_cache:
            buffer_lists.append(file_path)
        temp = {'Event': 'CachedBufferList', 'Lists': buffer_lists}
        self._pass_results_queue.put(temp)

    def BufferHanlder(self, version):
        if not version['UsingTextDiffer']:
            return version['AllTextList']
        file_path = version['FilePath']
        file_type = version['FileType']
        if version['IsFullList']:
            # not cache
            lists = version['AllTextList']
            if lists != ['']:
                self._buffer_cache[file_path] = lists
            else:
                self._buffer_cache[file_path] = []
            self.OutputCachedBuffer()
            return lists
        else:
            if file_type in ['nothing', 'leaderf']:
                return None
            # cached
            try:
                command = version['Commands']
                if self._is_debug:
                    original = copy.copy(self._buffer_cache[file_path])
                self.ApplyDiffer(command)
                lists = self._buffer_cache[file_path]
                if self._is_debug and lists != []:
                    if lists != version['AllTextList'] and version['AllTextList'] != ['']:
                        g_logger.debug('original:' + str(original))
                        g_logger.debug('commands:' + str(command))
                        g_logger.debug('wrongs.' + str(lists))
                        g_logger.debug('correct:' + str(version['AllTextList']))
                return lists
            except:
                g_logger.exception(str(command))
                self.OutputCachedBuffer(delete_buffer_path=file_path)
        return None
