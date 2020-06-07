# Author: Jimmy Huang (1902161621@qq.com)
# Some of codes were copy from YCM's typescript_completer.py

import logging
import json
import sys
import os
from tempfile import NamedTemporaryFile
import queue
import threading
import subprocess
import shlex
global g_logger
g_logger = logging.getLogger('ECY_server')

import ECY.utils.interface as scope_


class Operate(scope_.Source_interface):
    def __init__(self):
        """ notes: 
        """
        self._name = 'typescript_lsp'
        self._did_open_list = {}
        self.is_server_start = 'not_started'
        self._tsserver_msg_queue = {}
        self._tsserver_id = 0
        self._opened_file_name = {}
        self._deamon_queue = None

    def GetInfo(self):
        return {'Name': self._name, 'WhiteList': ['javascript', 'typescript'],
                'Regex': r'[A-Za-z0-9\_]',
                'TriggerKey': [".","\"","'","/","@","<"]}

    def _check(self, version):
        self._deamon_queue = version['DeamonQueue']
        self._start_server(version['StartingCMD'])
        if self.is_server_start == 'ok':
            return True
        return False

    def _start_server(self, starting_cmd):
        if self.is_server_start != 'not_started':
            return
        try:
            cmd = shlex.split(starting_cmd)
            self._tsserver_handle = subprocess.Popen(cmd,
                    shell=True,
                    stdin=subprocess.PIPE,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT)
            threading.Thread(target=self._read_msg_loop, daemon=True).start()
            self._get_queue('typingsInstallerPid')
            self.is_server_start = 'ok'
            g_logger.debug('started TSServer.')
        except:
            # timeout
            self._build_erro_msg(3, 'Failed to start tsserver.')
            self.is_server_start = 'failed'
            g_logger.exception('timeout, Failed to start tsserver.')

    def _get_queue(self, event_name, ids=-1, timeout=5):
        if not event_name in self._tsserver_msg_queue.keys():
            self._tsserver_msg_queue[event_name] = queue.Queue()

        while 1:
            if timeout == -1:
                msg = self._tsserver_msg_queue[event_name].get()
            else:
                msg = self._tsserver_msg_queue[event_name].get(timeout=5)
            if ids != -1 and 'request_seq' in msg.keys():
                if msg['request_seq'] == ids:
                    return msg
            else:
                return msg

    def _put_queue(self, event_name, msg):
        if not event_name in self._tsserver_msg_queue.keys():
            self._tsserver_msg_queue[event_name] = queue.Queue()
        self._tsserver_msg_queue[event_name].put(msg)
        g_logger.debug(msg)

    def _read_msg_loop(self):
        while 1:
            try:
                msg_dict = self._read_msg()
                g_logger.debug(msg_dict)
                if 'command' in msg_dict.keys():
                    event_type = msg_dict['command']
                elif 'event' in msg_dict.keys():
                    event_type = msg_dict['event']
                else:
                    event_type = 'others'
                if not event_type == 'reload':
                    self._put_queue(event_type, msg_dict)
            except:
                g_logger.exception('')

    def _to_bytes(self, value):
        if not value:
            return bytes()

        if type( value ) == bytes:
            return value

        if isinstance( value, bytes ):
            return bytes( value, encoding = 'utf8' )

        if isinstance( value, str ):
          return bytes( value, encoding = 'utf8' )
        return self._to_bytes( str( value ) )

    def _to_unicode(self, value):
        if not value:
            return str()
        if isinstance( value, str ):
            return value
        if isinstance( value, bytes ):
            # All incoming text should be utf8
            return str( value, 'utf8' )
        return str( value )

    def _did_open_or_change(self, version):
        file_name = version['FilePath']
        if file_name in self._opened_file_name.keys():
          try:
            os.remove(self._opened_file_name[file_name])
          except:
            pass
        tmpfile = NamedTemporaryFile(delete=False)
        tmpfile.write(self._to_bytes(version['AllTextList']))
        tmpfile.close()
        self._opened_file_name[file_name] = tmpfile
        return self._SendRequest('reload', {
          'file':    file_name,
          'tmpfile': tmpfile.name
        })

    def _SendRequest( self, command, arguments=None, types='request'):
        """
        Send a message to TSServer.
        """
        self._tsserver_id += 1
        request = {
          'seq':     self._tsserver_id,
          'type':    types,
          'command': command
        }
        if arguments:
          request[ 'arguments' ] = arguments
        serialized_request = self._to_bytes(
            json.dumps( request, separators = ( ',', ':' ) ) + '\n' )
        try:
            self._tsserver_handle.stdin.write( serialized_request )
            self._tsserver_handle.stdin.flush()
        except:
            pass
        g_logger.debug(serialized_request)
        return self._tsserver_id

    def _read_msg(self):
        """Read a response message from TSServer."""

        # The headers are pretty similar to HTTP.
        # At the time of writing, 'Content-Length' is the only supplied header.
        headers = {}
        while True:
          headerline = self._tsserver_handle.stdout.readline().strip()
          if not headerline:
            break
          key, value = self._to_unicode( headerline ).split( ':', 1 )
          headers[ key.strip() ] = value.strip()

        # The response message is a JSON object which comes back on one line.
        # Since this might change in the future, we use the 'Content-Length'
        # header.
        if 'Content-Length' not in headers:
          raise RuntimeError( "Missing 'Content-Length' header" )
        content_length = int( headers[ 'Content-Length' ] )
        # TSServer adds a newline at the end of the response message and counts it
        # as one character (\n) towards the content length. However, newlines are
        # two characters on Windows (\r\n), so we need to take care of that. See
        # issue https://github.com/Microsoft/TypeScript/issues/3403
        content = self._tsserver_handle.stdout.read( content_length )
        if sys.platform == 'win32' and content.endswith( b'\r' ):
          content += self._tsserver_handle.stdout.read( 1 )
        return json.loads( self._to_unicode( content ) )

    def _output_queue(self, msg):
        if self._deamon_queue is not None and msg is not None:
            msg['EngineName'] = self._name
            self._deamon_queue.put(msg)

    def _build_erro_msg(self, code, msg):
        """and and send it
        """
        msg = msg.split('\n')
        temp = {'ID': -1, 'Results': 'ok', 'ErroCode': code,
                'Event': 'erro_code',
                'Description': msg}
        self._output_queue(temp)

    def Goto(self, version):
        if self._check(version):
            self._did_open_or_change(version)
        return None

    def OnBufferEnter(self, version):
        if self._check(version):
            self._did_open_or_change(version)
        return None
        

    def OnBufferTextChanged(self, version):
        if self._check(version):
            self._did_open_or_change(version)
        return None

    def DoCompletion(self, version):
        if not self._check(version):
            return None
        request_id = self._SendRequest('completions', {
          'file':   version['FilePath'],
          'line':   version['StartPosition']['Line'],
          'offset': version['StartPosition']['Colum'],
          'includeExternalModuleExports': True
        })
        try:
            source = self._get_queue('completions', ids=request_id)
        except:
            # timeout
            source = {}
            pass
