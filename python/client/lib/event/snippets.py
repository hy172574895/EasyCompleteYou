# Author: Jimmy Huang (1902161621@qq.com)
# License: WTFPL

import os
import json
import logging
global g_logger
g_logger = logging.getLogger('ECY_client')

import lib.scope as scope_
import lib.vim_or_neovim_support as vim_lib


class Operate(scope_.Event):
    def __init__(self, source_name):
        scope_.Event.__init__(self, source_name)
        self.preview_file_dir = None
        self.preview_file_list = []
        self.preview_content = {}

    def _list_preview_file(self):
        if self.preview_file_dir is None:
            try:
                self.preview_file_dir = vim_lib.GetVariableValue("g:snippets_preview_dir")
                os.chdir(self.preview_file_dir)
                file_list = os.listdir(os.curdir)
                for item in file_list:
                    if os.path.isfile(item):
                        self.preview_file_list.append(item)
                g_logger.debug(self.preview_file_list)
            except:
                g_logger.exception("have no preview file path.")
                self.preview_file_dir = 'failed to get variable.'
                self.preview_file_list = []
        return self.preview_file_list

    def _read_preview_file(self, file_path):
        try:
            f = open(file_path, 'r', encoding='utf-8')
            txt = f.read()
            dicts = json.loads(txt)
            f.close()
            return dicts
        except:
            g_logger.exception("Failed to load preview file.")
            return {}

    def _get_preview_content(self):
        file_type = vim_lib.GetCurrentBufferType()
        if  file_type not in self.preview_content.items():
            self.preview_content[file_type] = {}
            for item in self._list_preview_file():
                if item == file_type:
                    dicts = self._read_preview_file(self.preview_file_dir + file_type)
                    self.preview_content[file_type] = dicts
                    break
        return self.preview_content[file_type]
        

    def OnBufferEnter(self):
        self._get_snippets(is_reflesh=True)
        return self._pack({}, 'OnBufferEnter')

    def DoCompletion(self):
        msg = {}
        msg['Additional'] = self._get_snippets()
        msg['SnippetsPreview'] = self._get_preview_content()
        return self._pack(msg, 'DoCompletion')
