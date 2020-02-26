# Author: Jimmy Huang (1902161621@qq.com)
# License: WTFPL
import logging
global g_logger
g_logger = logging.getLogger('ECY_client')

import lib.vim_or_neovim_support as vim_lib


class Event(object):
    """
    """

    def __init__(self, source_name):
        self._workspace = None
        self.source_name = source_name
        self._is_return_match_point = vim_lib.GetVariableValue(
            "g:ECY_use_floating_windows_to_be_popup_windows")
        self._trigger_len = vim_lib.GetVariableValue("g:ECY_triggering_length")
        self.has_ultisnippet_support = vim_lib.GetVariableValue(
            "g:has_ultisnips_support")
        self._snippets_cache = None

    def GetCurrentWorkSpace(self):
        temp = vim_lib.CallEval("ECY#rooter#GetCurrentBufferWorkSpace()")
        if temp == '':
            temp = None
        return temp

    def ChangeSourceName(self, source_name):
        self.source_name = source_name

    def DoCompletion(self):
        msg = {}
        msg['TriggerLength'] = self._trigger_len
        msg['ReturnMatchPoint'] = self._is_return_match_point
        return self._pack(msg, 'DoCompletion')

    def InstallSource(self):
        msg = {}
        temp = vim_lib.GetVariableValue('g:ecy_source_name_2_install')
        msg['EngineLib'] = temp['EngineLib']
        msg['EnginePath'] = temp['EnginePath']
        msg['EngineName'] = temp['EngineName']
        return self._pack(msg, 'InstallSource')

    def OnBufferEnter(self):
        self._workspace = self.GetCurrentWorkSpace()
        return self._pack({}, 'OnBufferEnter')

    def OnBufferTextChanged(self):
        return self._pack({}, 'OnBufferTextChanged')

    def OnInsertModeLeave(self):
        return self._pack({}, 'OnInsertModeLeave')

    def Goto(self):
        msg = {}
        msg['GotoLists'] = vim_lib.GetVariableValue('g:ECY_goto_info')
        return self._pack(msg, 'Goto')

    def Integration(self):
        msg = {}
        msg['Integration_event'] = vim_lib.GetVariableValue(
            'g:ECY_do_something_event')
        return self._pack(msg, 'integration')

    def GetAvailableSources(self):
        return self._pack({}, 'GetAvailableSources')

    def _pack(self, msg, event_name):
        msg = self._basic(msg)
        msg['Event'] = event_name
        return msg

    def _get_snippets(self, is_reflesh=False):
        if not self.has_ultisnippet_support:
            results = {'HasSnippetSupport': False}
        else:
            results = {'HasSnippetSupport': True}
            try:
                if is_reflesh or self._snippets_cache is None:
                    vim_lib.CallEval('UltiSnips#SnippetsInCurrentScope(1)')
                    self._snippets_cache =\
                            vim_lib.GetVariableValue('g:current_ulti_dict_info')
                results['UltisnipsSnippets'] = self._snippets_cache
            except:  # noqa
                results = {'HasSnippetSupport': False}
        return results

    def _is_return_diagnosis(self):
        return vim_lib.GetVariableValue("g:ECY_enable_diagnosis")

    def _basic(self, msg):
        msg['AllTextList'] = vim_lib.CurrenBufferText()
        msg['CurrentLineText'] = vim_lib.CurrentLineContents()
        msg['FileType'] = vim_lib.GetCurrentBufferType()
        msg['FilePath'] = vim_lib.GetCurrentBufferFilePath()
        msg['ReturnDiagnosis'] = self._is_return_diagnosis()
        # vim_lib.CurrentColumn is 0-based, and also CurrenLineNr()
        start_position = {
            'Line': vim_lib.CurrenLineNr(), 'Colum': vim_lib.CurrentColumn()}
        msg['StartPosition'] = start_position
        msg['SourceName'] = self.source_name
        msg['WorkSpace'] = self._workspace
        return msg
