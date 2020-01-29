# Author: Jimmy Huang (1902161621@qq.com)
# License: WTFPL

import argparse
import sys
parser = argparse.ArgumentParser(description='EasyCompleteYou, Easily complete you.')
parser.add_argument('--debug_log', action='store_true', help='debug with log')
parser.add_argument('--input_with_socket', action='store_true', 
                    help='accept socket data to input. using stdio is default. And you have to give the HMAC and PORT')
parser.add_argument('--output_with_socket', action='store_true', 
                    help='output results to socket. using stdio is default')
parser.add_argument('--output_not_with_stdio', action='store_true', 
                    help='do not ouput results to stdio')
parser.add_argument('--hmac', help='the security key of socket communication')
parser.add_argument('--port', help='the port of socket')
parser.add_argument('--log_dir', help='the file of log to output')
g_args = parser.parse_args()
# for my testing:
# D:\gvim\vimfiles\myplug\ECY_new\python\server\Main_server.py --hmac 1234 --port 1234 --input_with_socket
if g_args.input_with_socket:
    from socket import *    # noqa
    from base64 import b64decode
    import hmac

import json
import queue
import threading
import os.path as p

# local lib
from utils.ECY_logger import ECY_logger as ecy_logger
import lib.on_buffer as buffer_things
import lib.completion as completion
import lib.completor_manager as sources_manager
import lib.integration as integration
import lib.diagnosis as diagnosis

if g_args.log_dir is None:
    output_log_dir = p.dirname( p.abspath( __file__ ) )
    # output_log_dir = p.dirname( output_log_dir )
    output_log_dir = output_log_dir + "/server_log"
else:
    output_log_dir = g_args.log_dir
g_logger = ecy_logger(g_args.debug_log, output_log_dir).GetLogger()

g_queue = queue.Queue()

# {{{

class SocketDataHander(object):
    def __init__(self, HMAC_KEY=None):
        self._HMAC_KEY = bytes(str(HMAC_KEY), encoding='utf-8')

    def HandData(self, data):
        if data['Method'] == 'receive_all_msg':
            # requires id, msg, and key
            _msg_byte = bytes(str(data['Msg']), encoding='utf-8')
            HMAC_abstract2 = bytes(data['Key'], encoding='utf-8')
            HMAC_abstract2 = b64decode(HMAC_abstract2)
            # we are using MD5, it's safe enough for us, because the key is 
            # too complicated.
            HMAC_abstract1 = hmac.new(self._HMAC_KEY, _msg_byte).digest()
            if hmac.compare_digest(HMAC_abstract1, HMAC_abstract2):
                _todo = {'Msg': data['Msg']}
                self.AddTodo(_todo)
            else:
                # TODO: handle an unkonw msg
                pass

    def AddTodo(self, todo):
        """add it to queue. Handle by vim in queue.
        varible todo is fixed form.
        """
        # queue is thread-safe
        g_queue.put(todo)

class StdioDataHander(object):
    # TODO
    def HandData(self, data):
        if data['Method'] == 'receive_all_msg':
            _todo = {'Msg': data['Msg']}
            self.AddTodo(_todo)

    def AddTodo(self, todo):
        """add it to queue. Handle by vim in queue.
        varible todo is fixed form.
        """
        # queue is thread-safe
        g_queue.put(todo)


class Server(object):
    def __init__(self, port, hmac_str, is_use_socket):
        if not is_use_socket:
            self.thread = threading.Thread(target=self.StdioLoop)
            self.stdio_data_handler = StdioDataHander()
        else:
            self.HOST = ''
            # for security reason, we have to make sure the client is the right one.
            self.BUFSIZ = 1024*1000

            self.ADDR = (self.HOST, int(port))
            self.tcpSerSock = socket(AF_INET, SOCK_STREAM)
            self.tcpSerSock.bind(self.ADDR)
            self.tcpSerSock.listen(20)

            self.thread = threading.Thread(target=self.SocketLoop)
            # with HMAC for socket
            self.socket_data_handler = SocketDataHander(hmac_str)
        self.thread.daemon = True
        self.thread.start()

    def StdioLoop(self):
        # TODO
        g_logger.debug("using stdio to input") 
        data_bytes = b''
        while True:
            try:
                temp          = sys.stdin.readline()
                data_bytes   += bytes(temp, encoding="UTF-8")
                part_bytes    = data_bytes.split(b'\n')
                the_last_one  = len(part_bytes) - 1
                data_bytes    = part_bytes[the_last_one]
                i             = 0
                while i < the_last_one:
                    data_json = json.loads(part_bytes[i],encoding="utf-8")
                    i += 1
                    self.stdio_data_handler.HandData(data_json)
            except Exception as erro:
                g_logger.debug(temp) 
                g_logger.opt(exception=True).debug("exception:")
                raise

    def SocketLoop(self):
        g_logger.debug("using socket to input") 
        while True:
            tcpCliSock, addr = self.tcpSerSock.accept()
            data_bytes = b''
            # tcpCliSock.settimeout(5)
            try:
                while True:
                    data_bytes += tcpCliSock.recv(self.BUFSIZ)
                    if not data_bytes:
                        break
                    part_bytes = data_bytes.split(b'\n')
                    # we make sure every recived json can be loaded with no erro.
                    # a simple C/S
                    # if the last one in the variable part_bytes is empty
                    # so it's incomplete
                    the_last_one = len(part_bytes)-1
                    data_bytes = part_bytes[the_last_one]
                    i = 0
                    while i < the_last_one:
                        data_json = json.loads(part_bytes[i])
                        i += 1
                        self.socket_data_handler.HandData(data_json)
            except Exception as e:
                g_logger.opt(exception=True).debug("exception:")
                # time out or something wrong.
                # maybe that data is too big. we donot accept that big data beacause
                # this server just like a callback event
            finally:
                tcpCliSock.close()
        self.tcpSerSock.close()
# }}}


class GetTodo(object):
    def __init__(self, 
                 is_output_result_to_socket, is_output_result_to_stdio=True):
        self._is_output_socket = is_output_result_to_socket
        self._is_output_stdio = is_output_result_to_stdio
        self.thread = threading.Thread(target=self.Handler)
        self.thread.daemon = True
        self.pass_2_vim_queue = queue.Queue()
        self.event_handler = EventHandler(self.pass_2_vim_queue)
        self.thread.start()
        self.PassResults2Vim()

    def Handler(self):
        while 1:
            try:
                todo_dict = g_queue.get()
                todo_dict = self.event_handler.Pass2Hanlder(todo_dict)
                for item in todo_dict:
                    if item is not None:
                        self.pass_2_vim_queue.put(item)
            except Exception as erro:
                g_logger.opt(exception=True).debug("exception:")
                # self.pass_2_vim_queue.put({'Event': 'erro', 'Erro': erro})

    def PassResults2Vim(self):
        try:
            while 1:
                temp = json.dumps(self.pass_2_vim_queue.get())
                if self._is_output_stdio:
                    self.StdioOutput(temp)
                if self._is_output_socket:
                    # TODO
                    pass
        except Exception as erro:
            g_logger.opt(exception=True).debug("exception:")

    def StdioOutput(self, sending_data):
        sys.__stdout__.write(sending_data + '\n')
        sys.__stdout__.flush()


class EventHandler(object):
    def __init__(self, vim_queue):
        try:
            self.completion = completion.Operate()
            self.pass_2_vim_queue = vim_queue
            self.source_manager = sources_manager.Operate()
            self.on_buffer = buffer_things.Operate()
            self.integration = integration.Operate()
            self.diagnosis = diagnosis.Operate()
        except Exception as e:
            g_logger.opt(exception=True).debug("exception:")
            raise

    def Pass2Hanlder(self, version_dict):
        # the following key is needed all the way.
        version_dict = version_dict['Msg']
        event_ = version_dict['Event']
        file_type = version_dict['FileType']
        source_name = version_dict['SourceName']


        results_ = []
        # all the request must choose a source, when it's omit, we will give it
        # one
        if event_ == 'GetAvailableSources':
            temp = self.source_manager.GetAvailableSourceForFiletype(file_type)
            results_.append(temp)
            return results_

        # we passing that queue to let source handle asyn by itself.
        # if the source's event will block for a while, the source can return
        # None, and then put the result into deamon_queue when it finished
        version_dict['DeamonQueue'] = self.pass_2_vim_queue
        object_ = self.source_manager.GetSourceObjByName(source_name, file_type)

        # all the event must return something, if returning None
        # means returning nothing that do not need to send back to vim's side.
        if event_ == 'DoCompletion':
            temp = self.completion.DoCompletion(object_, version_dict)
        elif event_ == 'OnBufferEnter':
            temp = self.on_buffer.OnBufferEnter(object_, version_dict)
        elif event_ == 'Diagnosis':
            temp = self.diagnosis.Diagnosis(object_, version_dict)
        elif event_ == 'integration':
            temp = self.integration.HandleIntegration(object_, version_dict)
        elif event_ == 'InstallSource':
            temp = self.source_manager.InstallSource(version_dict['SourcePath'])
            results_.append(temp)
            temp = self.source_manager.GetAvailableSourceForFiletype(file_type)
        results_.append(temp)
        return results_


Server(g_args.port, g_args.hmac, g_args.input_with_socket)  # receiver

if not g_args.input_with_socket:
    g_args.output_with_socket = False
GetTodo(g_args.output_with_socket, not g_args.output_not_with_stdio) # handler
