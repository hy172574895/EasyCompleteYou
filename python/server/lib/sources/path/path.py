# Author: Jimmy Huang (1902161621@qq.com)
# License: WTFPL

# standard lib
import sys
import re
import os
import logging
global g_logger
g_logger = logging.getLogger('ECY_server')
# local lib
import ECY.utils.interface as scope_
# from utils import vim_or_neovim_support as vim_lib


class Operate(scope_.Source_interface):
    def __init__(self):
        self._name = 'path'
        self._ignore_regex = None

    def GetInfo(self):
        # the key of 'Regex' is the regular of filter
        temp = {'Name': self._name, 'WhiteList': ['all'],
                    'Regex': r'[a-z0-9\-\.\~\&\$]', 'TriggerKey': ['/','\\']}
        if self._current_system() == 'Windows':
            # such as 'C:\windows\gvim\'
            temp['TriggerKey'] = ['/','\\',':']
        return temp

    def _ignore(self, item, regexs):
        if type(regexs) != dict or regexs is None:
            return False

        if not 'dir' in regexs:
            regexs['dir'] = []
        if not 'file' in regexs:
            regexs['file'] = []

        if os.path.isfile(item):
            regex = regexs['file']
        else:
            regex = regexs['dir']

        if type(regex) != list:
            return False

        for line in regex:
            try:
                if re.search(line, item) != None:
                    return True
            except:
                pass
        return False

    def _return_path(self, file_list, prefix):
        results_list = []
        for item in file_list:
            # the results_format must at least contain the following keys.
            results_format = {'abbr': '', 'word': '', 'kind': '',
                    'menu': '', 'info': '','user_data':''}
            results_format['abbr'] = item
            results_format['word'] = item
            if self._ignore(item, self._ignore_regex):
                g_logger.debug('ignore')
                continue
            if os.path.isfile(item):
                results_format['kind'] = '[File]'
            elif os.path.isdir(item):
                results_format['kind'] = '[Dir]'
                results_format['abbr'] = item + '/'
            elif os.path.isabs(item):
                results_format['kind'] = '[Abs]'
            elif os.path.islink(item):
                results_format['kind'] = '[Link]'
            elif os.path.ismount(item):
                results_format['kind'] = '[Mount]'
            else:
                results_format['kind'] = 'Unkown'

            if prefix != '': 
                # using workspace symbols 
                full_path = prefix + item
            else:
                full_path = item
            if results_format['kind'] == '[Dir]':
                full_path += '/'
            full_path = full_path.split('\n')
            results_format['info'] = full_path
            results_list.append(results_format)
        return results_list

    def DoCompletion(self, version):
        return_ = {'ID': version['VersionID'], 'Lists': []}
        current_line_text = version['CurrentLineText']
        current_colum = version['Filter_start_position']['Colum']
        pre_words = current_line_text[:current_colum]

        workspace = version['WorkSpace']
        self._ignore_regex = version['Ignore']
        reg = r'[\w\-\.\~\/\\]'
        if self._current_system() == 'Windows':
            reg = r'[\w\-\.\~\/\\\:]'
        # only return 2 values
        current_colum, path = self.FindStart(pre_words, reg)

        prefix = ''
        if workspace is not None and len(path) > 0:
            if path[0] in ['~', '.']:
                # most of the language like "~/gvim" ro ".\gvim"
                workspace = workspace + path[1:]
            elif path[0] in ['\\','/']:
                # such as html
                workspace = workspace + path
            else:
                # we try anyway.
                workspace = workspace + "/" + path
            try:
                # try it with workspace
                os.chdir(workspace)
                file_list = os.listdir(os.curdir)
                prefix = workspace
            except:
                pass

        if prefix == '':
            try:
                # try it with no workspace
                if path[0] in ['~', '.']:
                    prefix = os.curdir
                    file_list = os.listdir(prefix + path[1:])
                    g_logger.debug(os.curdir)
                else:
                    os.chdir(path)
                    file_list = os.listdir(os.curdir)
            except:
                # return buffer id
                return return_

        prefix = prefix.replace("\\\\",'/')
        prefix = prefix.replace("\\",'/')
        # we have file_list
        return_['Lists'] = self._return_path(file_list, prefix)
        return return_

    def _current_system(self):
        temp = sys.platform
        if temp == 'win32':
            return 'Windows'
        if temp == 'cygwin':
            return 'Cygwin'
        if temp == 'darwin':
            return 'Mac'
