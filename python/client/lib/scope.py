import lib.vim_or_neovim_support as vim_lib

class Event(object):
    """
    """
    def __init__(self, source_name):
        self.source_name = source_name
        self._isReturn_match_point = False
        if vim_lib.GetVariableValue("g:ECY_use_floating_windows_to_be_popup_windows"):
            self._isReturn_match_point = True

        self._trigger_len = vim_lib.GetVariableValue("g:ECY_triggering_length")
        self.has_ultisnippet_support = vim_lib.GetVariableValue("g:has_ultisnips_support")

    def ChangeSourceName(self, source_name):
        self.source_name = source_name

    def DoCompletion(self):
        msg = {}
        msg['TriggerLength'] = self._trigger_len
        msg['ReturnMatchPoint'] = self._isReturn_match_point
        return self._pack(msg, 'DoCompletion')

    def OnBufferEnter(self):
        return self._pack({}, 'OnBufferEnter')
        
    def _pack(self, msg, event_name):
        msg = self._basic(msg)
        msg['Event'] = event_name
        msg['Additional'] = self._additional(msg['SourceName'], event_name)
        return msg

    def _additional(self, source_name, event_name):
        if not self.has_ultisnippet_support:
            results = {'HasSnippetSupport': False}
        else:
            results = {'HasSnippetSupport': True}
            try:
                vim_lib.CallEval('UltiSnips#SnippetsInCurrentScope(1)')
                results['UltisnipsSnippets'] = vim_lib.\
                    GetVariableValue('g:current_ulti_dict_info')
            except: # noqa
                results = {'HasSnippetSupport': False}
        return results

    def _basic(self, msg):
        msg['AllTextList']     = vim_lib.CurrenBufferText()
        msg['CurrentLineText'] = vim_lib.CurrentLineContents()
        msg['FileType']        = vim_lib.GetCurrentBufferType()
        msg['FilePath']        = vim_lib.GetCurrentBufferFilePath()
        # vim_lib.CurrentColumn is 0-based, and also CurrenLineNr()
        start_position         = {
            'Line': vim_lib.CurrenLineNr(), 'Colum': vim_lib.CurrentColumn()}
        msg['StartPosition'] = start_position
        msg['SourceName'] = self.source_name
        return msg
