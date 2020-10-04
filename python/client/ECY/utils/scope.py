# Author: Jimmy Huang (1902161621@qq.com)
# License: WTFPL
import ECY.utils.vim_or_neovim_support as vim_lib
import os
import json
import logging
# TODO
# import difflib
# from difflib import SequenceMatcher
global g_logger
g_logger = logging.getLogger('ECY_client')


class Event(object):
    """
    """

    def __init__(self, source_name):
        self._workspace = None
        self.source_name = source_name
        self._is_return_match_point = vim_lib.GetVariableValue(
            "g:ECY_use_floating_windows_to_be_popup_windows")
        self._trigger_len = vim_lib.GetVariableValue("g:ECY_triggering_length")
        self._is_debugging = vim_lib.GetVariableValue("g:ECY_debug")
        self._use_textdiffer = vim_lib.CallEval(
            'ECY_main#UsingTextDifferEvent()')
        self._snippets_cache = None
        self._lsp_setting = None

        self.preview_file_dir = None
        self.preview_file_list = []
        self.preview_content = {}
        # self._get_difference = MyDiffer()
        self.buffer_cache = {}

    def GetCurrentWorkSpace(self):
        temp = vim_lib.CallEval("ECY#rooter#GetCurrentBufferWorkSpace()")
        if temp == '':
            temp = None
        return temp

    def ChangeSourceName(self, source_name):
        self.source_name = source_name

#######################################################################
#                               events                                #
#######################################################################

    def InstallSource(self):
        """ user should not rewrite this method
        """
        msg = {}
        temp = vim_lib.GetVariableValue('g:ecy_source_name_2_install')
        msg['EngineLib'] = temp['EngineLib']
        msg['EnginePath'] = temp['EnginePath']
        msg['EngineName'] = temp['EngineName']
        return self._pack(msg, 'InstallSource')

    def Restart(self):
        return self._pack({}, 'Restart')

    def Exit(self):
        return self._pack({}, 'Exit')

    def DoCompletion(self):
        return self._pack({}, 'DoCompletion')

    def GetAllEngineInfo(self):
        return self._pack({}, 'GetAllEngineInfo')

    def OnDocumentHelp(self):
        return self._pack({}, 'OnDocumentHelp')

    def OnBufferEnter(self):
        return self._pack({}, 'OnBufferEnter')

    def OnBufferTextChanged(self):
        return self._pack({}, 'OnBufferTextChanged')

    def OnInsertModeLeave(self):
        return self._pack({}, 'OnInsertModeLeave')

    def Goto(self):
        return self._pack({}, 'Goto')

    def Integration(self):
        return self._pack({}, 'Integration')

    def GetAvailableSources(self):
        return self._pack({}, 'GetAvailableSources')

#######################################################################
#                                scope                                #
#######################################################################

    def _generate(self, msg, event_name):
        msg['Event'] = event_name
        if event_name == 'DoCompletion':
            msg['TriggerLength'] = self._trigger_len
            msg['ReturnMatchPoint'] = self._is_return_match_point
        if event_name == 'Goto':
            msg['GotoLists'] = vim_lib.GetVariableValue('g:ECY_goto_info')
        if event_name == 'OnBufferEnter':
            # update WorkSpace
            self._workspace = self.GetCurrentWorkSpace()
        if event_name == 'Integration':
            msg['Integration_event'] = vim_lib.GetVariableValue(
                'g:ECY_do_something_event')
        return self._basic(msg)

    def _pack(self, msg, event_name):
        return self._generate(msg, event_name)

#######################################################################
#                             get snippet                             #
#######################################################################

    def _get_snippets(self, is_reflesh=False):
        results = {'HasSnippetSupport': True}
        try:
            if is_reflesh or self._snippets_cache is None:
                vim_lib.CallEval('UltiSnips#SnippetsInCurrentScope(1)')
                self._snippets_cache =\
                    vim_lib.GetVariableValue('g:current_ulti_dict_info')
                preview = self._get_preview_content()
                for key in self._snippets_cache:
                    if key in preview.keys():
                        self._snippets_cache[key]['preview'] = preview[key]['preview']
                    else:
                        self._snippets_cache[key]['preview'] = []
            results['UltisnipsSnippets'] = self._snippets_cache
        except:
            results = {'HasSnippetSupport': False}
            g_logger.exception("Failed to load snippets.")
        return results

    def _list_preview_file(self):
        if self.preview_file_dir is None:
            self.preview_file_dir = vim_lib.CallEval(
                "get(g:, 'snippets_preview_dir', '1')")
            if self.preview_file_dir == '1':
                g_logger.debug("Not install plugin of preview.")
                self.preview_file_dir = 'failed to get variable.'
                self.preview_file_list = []
            else:
                try:
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
        if file_type not in self.preview_content.items():
            self.preview_content[file_type] = {}
            for item in self._list_preview_file():
                if item == file_type:
                    dicts = self._read_preview_file(
                        self.preview_file_dir + file_type)
                    self.preview_content[file_type] = dicts
                    break
        return self.preview_content[file_type]

#######################################################################
#                                basic                                #
#######################################################################

    def _is_return_diagnosis(self):
        return vim_lib.GetVariableValue("g:ECY_enable_diagnosis")

    def _get_lsp_setting_dict(self):
        if vim_lib.CallEval('get(g:, "ECY_lsp_setting_new_server", 0)') == 1 \
                or self._lsp_setting is None:
            self._lsp_setting = vim_lib.CallEval('lsp#GetDict()')
        return self._lsp_setting

    def _basic(self, msg):
        # msg['AllTextList'] = vim_lib.CurrenBufferText()
        file_path = vim_lib.GetCurrentBufferFilePath()
        # msg['TextLists'] = self._return_buffer(file_path)
        msg['FilePath'] = file_path
        msg['CurrentLineText'] = vim_lib.CurrentLineContents()
        msg['FileType'] = vim_lib.GetCurrentBufferType()
        msg['ReturnDiagnosis'] = self._is_return_diagnosis()
        # vim_lib.CurrentColumn is 0-based, and also CurrenLineNr()
        start_position = {
            'Line': vim_lib.CurrenLineNr(), 'Colum': vim_lib.CurrentColumn()}
        msg['StartPosition'] = start_position
        msg['SourceName'] = self.source_name
        msg['WorkSpace'] = self._workspace
        msg['lsp_setting'] = self._get_lsp_setting_dict()
        return self._return_buffer(msg, file_path)

#######################################################################
#                            using differ                             #
#######################################################################

    def _parse_differ_commands(self):
        infos = vim_lib.GetVariableValue('g:ECY_buffer_need_to_update')
        buffer_info = vim_lib.GetVariableValue(
            'g:ECY_cached_buffer_nr_to_path')
        vim_lib.Command('let g:ECY_buffer_need_to_update = {}')
        commands = {}
        g_logger.debug(infos)
        for buffer_nr in infos:
            info = infos[buffer_nr]
            buffer_path = buffer_info[buffer_nr]
            commands[buffer_path] = []
            # last_command = None
            for item in info:
                kind = item[0]
                start_line = int(item[1])
                end_line = int(item[2])
                # if last_command == item:
                #     continue
                # last_command = item
                deleted_line = 0
                for line in range(start_line, end_line + 1):
                    temp = {'kind': kind, 'line': line}
                    if kind != 'delete':
                        try:
                            evals = 'getbufline({0}, {1})'.format(
                                buffer_nr, line + 1)
                            temp['newtext'] = vim_lib.CallEval(evals)[0]
                        except:
                            continue
                    else:
                        temp['line'] -= deleted_line
                        deleted_line += 1
                    commands[buffer_path].append(temp)
        g_logger.debug(commands)
        return commands

    def _return_buffer(self, msg, file_path):
        """ return current buffer difference text.
        """
        msg['IsFullList'] = False
        msg['IsDebugging'] = self._is_debugging
        msg['UsingTextDiffer'] = self._use_textdiffer

        if self._use_textdiffer:
            cached_buffer = vim_lib.GetVariableValue(
                'g:ECY_server_cached_buffer')
        else:
            cached_buffer = []

        if self._is_debugging and self._use_textdiffer:
            current_buffer = vim_lib.CallEval('getbufline(bufnr(), 1, "$")')
            msg['AllTextList'] = current_buffer

        # TODO, there are bug in vim, check
        # https://github.com/vim/vim/issues/5840
        if self._use_textdiffer and file_path in cached_buffer:
            msg['Commands'] = self._parse_differ_commands()
        else:
            current_buffer = vim_lib.CallEval('getbufline(bufnr(), 1, "$")')
            msg['IsFullList'] = True
            msg['AllTextList'] = current_buffer

        return msg

# TODO, using python's difflib

# class MyDiffer(difflib.Differ):
#     """docstring for MyDiffer"""
#     # def __init__(self):
#     #     super(MyDiffer, self).__init__()

#     def _dump(self, tag, x, lo, hi):
#         for i in range(lo, hi):
#             return_ = {'index': i , 'kind': tag}
#             if tag != 'delete':
#                 return_['newline'] = x[i]
#             yield return_

#     def compare(self, a, b):
#         cruncher = SequenceMatcher(self.linejunk, a, b)
#         for tag, alo, ahi, blo, bhi in cruncher.get_opcodes():
#             if tag == 'replace':
#                 g = self._dump(tag, b, blo, bhi)
#             elif tag == 'delete':
#                 g = self._dump(tag, a, alo, ahi)
#             elif tag == 'insert':
#                 g = self._dump(tag, b, blo, bhi)
#             elif tag == 'equal':
#                 # g = self._dump(' ', a, alo, ahi)
#                 continue
#             else:
#                 raise ValueError('unknown tag %r' % (tag,))

#             yield from g
