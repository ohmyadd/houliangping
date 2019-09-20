import sys
import json
import time
import urllib
import traceback

import bs4
import requests
from selenium import webdriver

server_ip = sys.argv[1]
server_port = int(sys.argv[2])
server_url = 'http://%s:%d' % (server_ip, server_port)
js = "document.getElementsByTagName('{0}')[0].innerHTML = '{1}'"

wd1 = webdriver.Firefox()
wd1.get(server_url)

while True:
    # wait for a single request
    if len(wd1.current_url.split('/')) < 5:
        time.sleep(0.5)
        continue

    url = '/'.join(wd1.current_url.split("/")[4:]).decode("base64")
    h = json.loads(wd1.find_element_by_tag_name("pre").text)
    method = h['method']
    headers = h['headers']
    data = urllib.unquote(str(h['data'])) if method == 'POST' else None

    for i in headers.keys():
        if i.lower() in ['host', 'content-length']:
            headers.pop(i)

    # make profile
    profile = webdriver.FirefoxProfile()
    profile.add_extension("./modify_headers-0.7.1.1-fx.xpi")
    profile.set_preference("modifyheaders.headers.count", len(headers))
    for n, row in enumerate(headers.items()):
        profile.set_preference("modifyheaders.headers.action%d" % n, "Add")
        profile.set_preference("modifyheaders.headers.name%d" % n, row[0].lower())
        profile.set_preference("modifyheaders.headers.value%d" % n, row[1])
        profile.set_preference("modifyheaders.headers.enabled%d" % n, True)
    profile.set_preference("modifyheaders.config.active", True)
    profile.set_preference("modifyheaders.config.alwaysOn", True)

    # open the new firefox window
    wd2 = webdriver.Firefox(firefox_profile=profile)
    if method == 'GET':
        try:
            wd2.get(url)
        except Exception:
            traceback.print_exc()
        #wd2.get('https://httpbin.org/get?show_env=1')
    # if POST, use requests for the data
    elif method == 'POST':
        resp = None
        try:
            resp = requests.post(url, headers=headers, data=data)
        except Exception:
            traceback.print_exc()
        if resp:
            try:
                wd2.get(url)
            except Exception:
                traceback.print_exc()

            # mofidy <head> and <body>
            bp = bs4.BeautifulSoup(resp.content, 'lxml')
            print(resp.content)
            if 'Content-Type' in resp.headers.keys() and \
               'text' in resp.headers['Content-Type']:
                if bp.head:
                    newhtml = bp.head.text.replace("'", "\"").replace("\n", '')
                    wd2.execute_script(js.format('head', newhtml))
                if bp.body:
                    newhtml = bp.body.text.replace("'", "\"").replace("\n", '')
                    wd2.execute_script(js.format('body', newhtml))
            else:
                text = bp.body.text if bp.body else 'None'
                newhtml = text.encode("base64").replace("\n", '')
                wd2.execute_script(js.format('body', newhtml))
        else:
            try:
                wd2.get(url)
            except Exception:
                traceback.print_exc()

    while True:
        try:
            wd2.current_url
            time.sleep(0.5)
        except Exception:
            break
    try:
        wd2.quit()
    except Exception:
        traceback.print_exc()
    wd1.back()
