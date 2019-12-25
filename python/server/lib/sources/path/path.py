# standard lib
import sys
import re
import os
# local lib
import utils.interface as scope_
# from utils import vim_or_neovim_support as vim_lib


class Operate(scope_.Source_interface):
    def __init__(self):
        self._name = 'path'

    def GetInfo(self):
        # the key of 'Regex' is the regular of filter
        temp = {'Name': self._name, 'WhiteList': ['all'],
                    'Regex': r'[\w\-\.\~\&\$]', 'TriggerKey': ['/','\\']}
        if self._current_system() == 'Windows':
            # such as 'C:\windows\gvim\'
            temp['TriggerKey'] = ['/','\\',':']
        return temp

    def DoCompletion(self, version):
        return_ = {'ID': version['VersionID'], 'Server_name': self._name}

        line_text = version['AllTextList']
        current_line_text = version['CurrentLineText']
        current_colum = version['Filter_start_position']['Colum']
        # TODO:
        # working_space = version['WorkingSpace']
        pre_words = current_line_text[:current_colum]
        temp = r'[\w\-\.\~\/\\\&\$]'
        is_id = False
        if self._current_system() == 'Windows':
            temp = r'[\w\-\.\~\/\\\:]'
        # only return 2 values
        current_colum, path = self.FindStart(pre_words, temp)
        try:
            os.chdir(path)
            file_list = os.listdir(os.curdir)
        except Exception as e:
            is_id = True
            file_list = list(set(re.findall(r'\w+', line_text)))

        results_list = []
        for item in file_list:
            # the results_format must at least contain the following keys.
            results_format = {'abbr': '', 'word': '', 'kind': '',
                    'menu': '', 'info': '','user_data':''}
            results_format['abbr'] = item
            results_format['word'] = item
            if is_id:
                results_format['kind'] = '[ID]'
            else:
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
            results_list.append(results_format)
        return_['Lists'] = results_list
        return return_

    def _current_system(self):
        temp = sys.platform
        if temp == 'win32':
            return 'Windows'
        if temp == 'cygwin':
            return 'Cygwin'
        if temp == 'darwin':
            return 'Mac'
