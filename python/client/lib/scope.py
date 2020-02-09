# Author: Jimmy Huang (1902161621@qq.com)
# License: WTFPL

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
        self._is_return_diagnosis = vim_lib.GetVariableValue(
            "g:ECY_update_diagnosis_mode")

    def GetCurrentWorkSpace(self):
        temp = vim_lib.CallEval("rooter#GetCurrentBufferWorkSpace()")
        if temp == '':
            temp = None
        return temp

    def ChangeSourceName(self, source_name):
        self.source_name = source_name

    def DoCompletion(self):
        msg = {}
        msg['TriggerLength'] = self._trigger_len
        msg['ReturnMatchPoint'] = self._is_return_match_point
        msg['ReturnDiagnosis'] = self._is_return_diagnosis
        return self._pack(msg, 'DoCompletion')

    def Diagnosis(self):
        return self._pack({}, 'Diagnosis')

    def InstallSource(self):
        msg = {}
        msg['SourcePath'] = vim_lib.GetVariableValue(
            'g:ecy_source_name_2_install')
        return self._pack(msg, 'InstallSource')

    def OnBufferEnter(self):
        self._workspace = self.GetCurrentWorkSpace()
        return self._pack({}, 'OnBufferEnter')

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

    def _get_snippets(self):
        if not self.has_ultisnippet_support:
            results = {'HasSnippetSupport': False}
        else:
            results = {'HasSnippetSupport': True}
            try:
                vim_lib.CallEval('UltiSnips#SnippetsInCurrentScope(1)')
                results['UltisnipsSnippets'] = vim_lib.\
                    GetVariableValue('g:current_ulti_dict_info')
            except:  # noqa
                results = {'HasSnippetSupport': False}
        return results

    def _basic(self, msg):
        msg['AllTextList'] = vim_lib.CurrenBufferText()
        msg['CurrentLineText'] = vim_lib.CurrentLineContents()
        msg['FileType'] = vim_lib.GetCurrentBufferType()
        msg['FilePath'] = vim_lib.GetCurrentBufferFilePath()
        # vim_lib.CurrentColumn is 0-based, and also CurrenLineNr()
        start_position = {
            'Line': vim_lib.CurrenLineNr(), 'Colum': vim_lib.CurrentColumn()}
        msg['StartPosition'] = start_position
        msg['SourceName'] = self.source_name
        msg['WorkSpace'] = self._workspace
        return msg
