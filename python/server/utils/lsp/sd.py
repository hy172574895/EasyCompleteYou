from http.server import HTTPServer,BaseHTTPRequestHandler
import json

data = {'result':'this is a test'}
host = ('localhost', 8888)

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type','text/html')
        self.end_headers()
        self.wfile.write("sdf".encode())

server = HTTPServer(host, Handler)
print('Starting server, listen at: %s:%s' % host)
server.serve_forever()
