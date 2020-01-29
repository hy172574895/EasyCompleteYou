import subprocess
from socket import *
import shlex
import json
import threading
from http.server import BaseHTTPRequestHandler, HTTPServer

global hint_content
hint_content = 'ok'

class HtmlHint:
    def __init__(self):
        self._port = -1
        address = ('127.0.0.1', self.GetUnusedLocalhostPort())
        print(address)
        server = HTTPServer(address, Handler)
        threading.Thread(target=server.serve_forever).start()

    def GetUnusedLocalhostPort(self):
        if self._port == -1:
            sock = socket() # noqa
            # This tells the OS to give us any free port in the
            # range [1024 - 65535]
            sock.bind(('', 0))
            port = sock.getsockname()[1]
            self._port = port
            sock.close()
        return self._port

    def SetContent(self, text):
        hint_content = text

    def _get(self, cmd):
        """start annalysis and put results to queue
        """
        cmd = "htmlhint --format=json http://localhost:" + str(self.GetUnusedLocalhostPort())
        cmd = shlex.split(cmd)
        process = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
        if process.wait(timeout=5) is None:
            return -1
        return process.stdout.read()

    def GetDiagnosis(self, cmd):
        results = self._get(cmd).split(b'\n')
        if (results is None):
            # time out or something wrong
            return None
        results = results[0].decode("UTF-8")
        results = json.loads(results)
        results_list = []
        for item in results:
            file_path = item['file']
            for msg in item['messages']:
                msg['col'] += 1
                pos_string = '[' + str(msg['line']) + ', ' + str(msg['col']) + ']'
                position = {'line': msg['line'], 'range': {
                    'start': {'line': msg['line'], 'colum': msg['col']},
                    'end': {'line': msg['line'], 'colum': msg['col']}}}
                temp = [{'name': '1', 'content': {'abbr': msg['message']}},
                        {'name': '2', 'content': {'abbr': msg['type']}},
                        {'name': '3', 'content': {'abbr': file_path}},
                        {'name': '4', 'content': {'abbr': pos_string}}]
                temp = {'items': temp,
                        'type': 'diagnosis',
                        'diagnosis': msg['rule']['description'],
                        'position': position}
                results_list.append(temp)
        return results_list
        
class Handler(BaseHTTPRequestHandler):

    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type','text/html')
        self.end_headers()
        self.wfile.write(hint_content.encode())

    def log_request(self, code='-', size='-'):
        pass

temp = HtmlHint()
temp.SetContent('sdf')
print(temp.GetDiagnosis('ds'))
