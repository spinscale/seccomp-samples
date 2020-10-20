#!/usr/bin/python3

import getopt, subprocess, sys

from http.server import BaseHTTPRequestHandler
from http.server import HTTPServer
from seccomp import *

class GetHandler(BaseHTTPRequestHandler):

    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-Type', 'text/plain; charset=utf-8')
        self.end_headers()
        output = subprocess.run(["/bin/ls", "-al"],  capture_output=True)
        self.wfile.write(output.stdout)

def setup_seccomp(log_only):
    f = SyscallFilter(ALLOW)
    #if not log_only:
    f.set_attr(Attr.CTL_LOG, 1)
    action = LOG if log_only else ERRNO(errno.EPERM)
    # stop executions
    f.add_rule(action, "execve")
    f.add_rule(action, "execveat")
    f.add_rule(action, "vfork")
    f.add_rule(action, "fork")
    f.load()
    print(f'Seccomp enabled...')

def usage():
    print(f'Usage {sys.argv[0]}\n')
    print(f'   -s --seccomp    Enable seccomp, disabled by default')
    print(f'   -l --log        Log seccomp violations only, disabled by default')
    print(f'   -p= --port=     Bind to port, defaults to 8081')
    print(f'   --help          This help')

if __name__ == '__main__':
    port = 8081
    seccomp = False
    log = False
    try:
        opts, args = getopt.getopt(sys.argv[1:], "hslp:", ["help", "seccomp", "port=", "log"])
    except getopt.GetoptError as err:
        print(err)
        usage()
        sys.exit(2)
    for o, a in opts:
        if o == "-s":
            seccomp = True
        elif o == "-l":
            log = True
            seccomp = True
        elif o in ("-h", "--help"):
            usage()
            sys.exit()
        elif o in ("-p", "--port"):
            port = int(a)
        else:
            assert False, "unhandled option"

    server = HTTPServer(('localhost', port), GetHandler)

    if seccomp:
      setup_seccomp(log)

    print(f'Listening on localhost:{port}')
    server.serve_forever()
