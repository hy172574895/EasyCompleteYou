# Author: Jimmy Huang (1902161621@qq.com)
# License: WTFPL

import importlib
import os
import configparser


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
        self._load_source()

    def _get_cache_file(self):
        if self._cache_file_name is None:
            path_temp = __file__
            if os.path.isfile(path_temp):
                path_temp = os.path.dirname(path_temp)
            path_temp = path_temp + '/user_cache/'
            if not os.path.exists(path_temp):
                # if there are no user_cache dir then make one
                os.mkdir(path_temp)
            self._cache_file_name = path_temp + '/ECY_config.ini'
        return self._cache_file_name

    def _load_config(self):
        """
        """
        path_temp = self._get_cache_file()
        if not os.path.exists(path_temp):
            # default config
            fp = open(path_temp, mode="w", encoding='utf-8')
            installed_completor = \
                {'lib.sources.label.Label': 'label',
                 'lib.sources.path.path': 'path',
                 'lib.sources.python.python': 'python_jedi'}
            self.conf['installed_completor'] = installed_completor
            self.conf['filetype_using'] = {}
            self.conf.write(fp)
            fp.close()
        else:
            self.conf.read(path_temp)
            installed_completor = self.conf['installed_completor']
        return installed_completor

    def _load_source(self, specify=None):
        """ load the installed source list when specify is None
        """
        try:
            if specify is None:
                loading_source_temp = self._load_config()
            else:
                loading_source_temp = [specify]

            for name_temp in loading_source_temp:
                # e.g.
                # name_temp = 'lib.sources.label.Label'
                module_temp = importlib.import_module(name_temp)
                obj_temp = module_temp.Operate()
                module_temp = obj_temp.GetInfo() # return a dict
                module_temp['Object'] = obj_temp
                completor_name = module_temp['Name']
                self.sources_info[completor_name] = module_temp
            return module_temp
        except Exception as e:
            raise

    def InstallSource(self, source_path):
        """this method will not check if it's runable.
        the source's depence must be checked in the vim side.
        """
        try:
            path_temp = self._get_cache_file()
            info_ = self._load_source(specify=source_path)
            self.conf.read(path_temp)
            self.conf['installed_completor'][source_path] = info_['Name']
            fp = open(path_temp, mode="w", encoding='utf-8')
            self.conf.write(fp)
            fp.close()
            return {'Event': 'install_source',
                    'Status': 0,
                    'Name': source_path,
                    'Description': 'Installation succeed.'}
        except: # noqa
            # TODO
            return {'Event': 'install_source',
                    'Status': 1,
                    'Name': source_path,
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
            current_using_source = 'nothing'
            self.conf.read(path_temp)
            if file_type not in self.conf['filetype_using']:
                current_using_source = 'label'
                self.conf['filetype_using'][file_type] = current_using_source
                fp = open(path_temp, mode="w", encoding='utf-8')
                self.conf.write(fp)
                fp.close()
            else:
                current_using_source = self.conf['filetype_using'][file_type]
            self.file_type_available_source[file_type]['using_source'] = \
                current_using_source
        return {'Event': 'set_file_type_available_source',
                'FileType': file_type,
                'Dicts': self.file_type_available_source[file_type]}

    def SetSourceForFileType(self, file_type, source_name=None, is_next_or_pre='next'): # noqa
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
            raise
        self.SetSourceForFileType(file_type, source_name=source_name)
        return self.sources_info[source_name]['Object']
