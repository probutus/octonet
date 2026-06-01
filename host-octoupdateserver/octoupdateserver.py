#!/usr/bin/python3
#to use updateserver create directory at same location of this file named "octonet" and put generated *img and *sha files in it, you have to add the filename you want to update into this script. See variable "FILENAME"
import http.server
import socketserver
import os

# configuration
PORT = 80
# add name of new image file
FILENAME = "octonet.2211010000.img"

class OctopusUpdateHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        # print request
        print(f"Got request: {self.path}")

        # lua script is asking for directory first: http://ip/octonet/
        if self.path == "/octonet/" or self.path == "/octonet":
            self.send_response(200)
            self.send_header("Content-type", "text/html")
            self.end_headers()
            # create directory which is expected by lua script  ["/](octonet%.%d+%.img)"
            response = f'<html><body><a href="{FILENAME}">{FILENAME}</a></body></html>'
            self.wfile.write(response.encode())
            print(f"--> Index delivered with file: {FILENAME}")
            return

        # when file is requested (either .img or .sha)
        return super().do_GET()

# start server
try:
    with socketserver.TCPServer(("", PORT), OctopusUpdateHandler) as httpd:
        print(f"OctopusNet Update-Server running on port {PORT}")
        print(f"expected path: http://<PC-IP>/octonet/")
        httpd.serve_forever()
except PermissionError:
    print("error: you need to be root to use port 80!")

