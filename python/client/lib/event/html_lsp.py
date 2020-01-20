import lib.scope as scope_
import lib.vim_or_neovim_support as vim_lib

class HtmlLSPEvent(scope_.Event):
    def __init__(self, source_name):
        self._starting_server_cmd = None
        scope_.Event.__init__(self, source_name)
        
    def _get_cmd_option(self):
        ''' After open a new filetype in Vim, ECY will ask the server what sources
        are available in that filetype, so 
        '''
        if self._starting_server_cmd is None:
            self._starting_server_cmd = vim_lib.CallEval("get(g:,'ECY_html_lsp_starting_cmd','html-languageserver --stdio')")
        return self._starting_server_cmd

    def OnBufferEnter(self):
        self._workspace = self.GetCurrentWorkSpace()
        msg = {}
        msg['StartingCMD'] = self._get_cmd_option()
        return self._pack(msg, 'OnBufferEnter')

    def DoCompletion(self):
        msg = {}
        msg['TriggerLength'] = self._trigger_len
        msg['ReturnMatchPoint'] = self._isReturn_match_point
        msg['StartingCMD'] = self._get_cmd_option()
        return self._pack(msg, 'DoCompletion')
