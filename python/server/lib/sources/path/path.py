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
        addtional_data = {}
        line_text = version['AllTextList']
        current_line_text = version['CurrentLineText']
        current_colum = version['Filter_start_position']['Colum']
        workspace = version['WorkSpace']
        pre_words = current_line_text[:current_colum]
        temp = r'[\w\-\.\~\/\\]'
        is_id = False
        if self._current_system() == 'Windows':
            temp = r'[\w\-\.\~\/\\\:]'
        # only return 2 values
        current_colum, path = self.FindStart(pre_words, temp)

        try:
            if workspace is not None :
                if path[0] in ['~', '.']:
                    # most of the language like "~/gvim" ro ".\gvim"
                    path_temp = workspace + path[1:]
                else:
                    # such as html
                    if path[0] in ['\\','/']:
                        path_temp = workspace + path
                    else:
                        path_temp = workspace + "/" + path
        except Exception as e:
            # the path is uncertain, so will we try at here
            pass
        # if not using WorkSpace, we set it None
        addtional_data['UsingWorkSpace'] = None
        try:
            # this will raise if workspace is None that is path_temp not define
            os.chdir(path_temp)
            file_list = os.listdir(os.curdir)
            addtional_data['Path'] = path_temp
            addtional_data['UsingWorkSpace'] = workspace
        except Exception as e:
            try:
                path_temp = path
                os.chdir(path)
                file_list = os.listdir(os.curdir)
                addtional_data['Path'] = path
            except Exception as e:
                is_id = True
                file_list = list(set(re.findall(r'\w+', line_text)))
                addtional_data['Path'] = None

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
                else:
                    results_format['kind'] = 'Unkown'

                if addtional_data['UsingWorkSpace'] is not None: 
                    results_format['menu'] = results_format['kind']
                    full_path = path_temp + item
                    if results_format['kind'] == '[Dir]':
                        full_path += '/'
                    results_format['info'] = full_path.replace("\\\\",'/')
                    results_format['info'] = full_path.replace("\\",'/')
                    results_format['info'] = results_format['info'].split('\n')
            results_list.append(results_format)
        return_['Lists'] = results_list
        return_['AddtionalData'] = addtional_data
        return return_

    def _current_system(self):
        temp = sys.platform
        if temp == 'win32':
            return 'Windows'
        if temp == 'cygwin':
            return 'Cygwin'
        if temp == 'darwin':
            return 'Mac'
