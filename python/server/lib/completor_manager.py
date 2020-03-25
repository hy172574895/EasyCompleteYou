# Author: Jimmy Huang (1902161621@qq.com)
# License: WTFPL

import importlib
import os
import sys
import configparser
import logging
from copy import deepcopy
global g_logger
g_logger = logging.getLogger('ECY_server')


class MyConf(configparser.ConfigParser):
    """rewrite super's class to support upper case.
    """

    def __init__(self, defaults=None):
        configparser.ConfigParser.__init__(self, defaults=None)

    def optionxform(self, optionstr):
        return optionstr


class Operate(object):
    def __init__(self):
        self.sources_info = {}
        self.conf = MyConf()
        self._cache_file_name = None
        self.file_type_available_source = {}
        self._load_engine()

    def _get_cache_file(self):
        if self._cache_file_name is None:
            path_temp = __file__
            if os.path.isfile(path_temp):
                path_temp = os.path.dirname(path_temp)
            path_temp = path_temp + '/user_cache/'
            if not os.path.exists(path_temp):
                # if there are no user_cache dir then make one
                os.mkdir(path_temp)
            self._cache_file_name = path_temp + '/ECY_server_config.ini'
        return self._cache_file_name

    def _load_config(self):
        """
        """
        path_temp = self._get_cache_file()
        if not os.path.exists(path_temp):
            # default config
            fp = open(path_temp, mode="w", encoding='utf-8')
            installed_engine_lib = \
                {'label': 'lib.sources.label.Label',
                 'path': 'lib.sources.path.path',
                 'disabled': 'lib.sources.youcompleteme.disable',
                 'python_jedi': 'lib.sources.python.python'}
            installed_engine_path = \
                {'label': '',
                 'path': '',
                 'disabled': '',
                 'python_jedi': ''}
            self.conf['installed_engine_lib'] = installed_engine_lib
            self.conf['installed_engine_path'] = installed_engine_path
            self.conf['filetype_using'] = {}
            self.conf.write(fp)
            fp.close()
        else:
            self.conf.read(path_temp)
            installed_engine_lib = self.conf['installed_engine_lib']
            installed_engine_path = self.conf['installed_engine_path']
        return installed_engine_lib, installed_engine_path

    def _load_engine(self, specify_lib=None, specify_path={}):
        """ load the installed source list when specify_lib is None
        e.g.
        specify_lib = {'engine_name': 'lib.sources.label.Label'}
        specify_path = {'engine_name': 'd:/gvim/xxx/'}
        """
        try:
            if specify_lib is None:
                loading_source_lib, loading_source_path = self._load_config()
            else:
                loading_source_lib = specify_lib
                loading_source_path = specify_path
                g_logger.debug('installing new engine')
                g_logger.debug(loading_source_lib)
                g_logger.debug(loading_source_path)

            module_temp = None
            # loading_source_lib is a dict
            for name, lib in loading_source_lib.items():
                # e.g.
                # name = 'label'
                # lib = 'lib.sources.label.Label'
                try:
                    if name in loading_source_path and \
                            loading_source_path[name] != '':
                        temp = loading_source_path[name]
                        sys.path.append(temp)
                        g_logger.debug('appended a new path:' + temp)
                    module_temp = importlib.import_module(lib)
                    obj_temp = module_temp.Operate()
                    module_temp = obj_temp.GetInfo()  # return a dict
                    module_temp['Object'] = obj_temp
                    name = module_temp['Name']
                    self.sources_info[name] = module_temp
                    g_logger.debug('installed: ' + name + " from " + lib)
                except:
                    # return erro
                    g_logger.exception("failed to load engine.")
            return module_temp
        except:
            raise "Failed to load engine."

    def InstallSource(self, engine_name, engine_lib, package_path=''):
        """this method will not check if engine is runable.
        the engine's depence must be checked in the vim side.
        """
        try:
            path_temp = self._get_cache_file()
            lib_dict = {}
            path_dict = {}
            lib_dict[engine_name] = engine_lib
            path_dict[engine_name] = package_path
            info_ = self._load_engine(specify_lib=lib_dict,\
                    specify_path=path_dict)
            if info_ is None:
                raise "Failed to Install a engine."
            self.conf.read(path_temp)
            self.conf['installed_engine_lib'][engine_name] = engine_lib
            self.conf['installed_engine_path'][engine_name] = package_path
            fp = open(path_temp, mode="w", encoding='utf-8')
            self.conf.write(fp)
            fp.close()
            return {'Event': 'install_source',
                    'Status': 0,
                    'Name': engine_lib,
                    'EngineName': engine_name,
                    'FileType': info_['WhiteList'],
                    'Description': 'Installation succeed.'}
        except:
            g_logger.exception("failed to install a new engine.")
            return {'Event': 'install_source',
                    'Status': 1,
                    'Name': engine_lib,
                    'Description': 'failed to load source, check out logging.'}

    def GetAvailableSourceForFiletype(self, file_type):
        if file_type == '':
            file_type = 'nothing'

        if file_type not in self.file_type_available_source:
            self.file_type_available_source[file_type] = {}
        temp = []
        for name_, value_ in self.sources_info.items():
            if file_type in value_['WhiteList'] or\
                    'all' in value_['WhiteList']:
                temp.append(name_)
        self.file_type_available_source[file_type]['available_sources'] = temp

        if 'using_source' not in self.file_type_available_source[file_type]:
            path_temp = self._get_cache_file()
            current_using_source = 'label'
            self.conf.read(path_temp)
            if file_type not in self.conf['filetype_using']:
                self.conf['filetype_using'][file_type] = current_using_source
                fp = open(path_temp, mode="w", encoding='utf-8')
                self.conf.write(fp)
                fp.close()
            else:
                history_using = self.conf['filetype_using'][file_type]
                if history_using in temp:
                    current_using_source = history_using
            self.file_type_available_source[file_type]['using_source'] = \
                current_using_source
        return {'Event': 'set_file_type_available_source',
                'FileType': file_type,
                'Dicts': self.file_type_available_source[file_type]}

    def SetSourceForFileType(self, file_type, source_name=None, is_next_or_pre='next'):  # noqa
        # init, firstly
        self.GetAvailableSourceForFiletype(file_type)

        setting_source_name = None
        available_sources = \
            self.file_type_available_source[file_type]['available_sources']
        if source_name is not None \
                and source_name in available_sources:
            setting_source_name = source_name
        else:
            current_using_source = \
                self.file_type_available_source[file_type]['using_source']
            available_sources_len = len(available_sources)
            current_using_res = available_sources.index(current_using_source)
            if is_next_or_pre == 'next':
                switching_souces = (current_using_res +
                                    1) % available_sources_len
            else:
                switching_souces = (current_using_res -
                                    1) % available_sources_len
            setting_source_name = available_sources[switching_souces]

        if setting_source_name is not \
                self.file_type_available_source[file_type]['using_source']:
            # write back to the dick
            self.file_type_available_source[file_type]['using_source'] = \
                setting_source_name
            self.conf.read(self._get_cache_file())
            self.conf['filetype_using'][file_type] = setting_source_name
            fp = open(self._get_cache_file(), mode="w", encoding='utf-8')
            self.conf.write(fp)
            fp.close()

        return {'Current_source': setting_source_name}

    def GetSourceObjByName(self, source_name, file_type):
        if source_name not in self.sources_info:
            # while user provide a SourceName we don't have.
            raise "[ECY] source_name you provide not in Server."
        self.SetSourceForFileType(file_type, source_name=source_name)
        return self.sources_info[source_name]['Object']

    def GetAllEngine(self, version):
        engine_info_temp = []
        for name, values in self.sources_info.items():
            temp = {}
            temp['Name'] = name
            temp['FileType'] = values['WhiteList']
            temp['TriggerKey'] = values['TriggerKey']
            engine_info_temp.append(temp)
        return_ = {'ID': version['VersionID']}
        return_['Event'] = 'all_engine_info'
        return_['EngineInfo'] = engine_info_temp
        return return_
