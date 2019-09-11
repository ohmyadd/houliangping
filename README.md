# houliangping
这是一个能够高效利用劫持到的http会话的程序

client使用selenium进行会话浏览

server作为会话信息来源，可以是嗅探、中间人等等

http://mirrors.aliyun.com/ubuntu-ports/pool/main/f/firefox/firefox_45.0.2+build1-0ubuntu1_armhf.deb

modify_headers-0.7.1.1-fx.xpi

1. docker run -it --name hou --rm --privileged --net=host -v /tmp/.X11-unix/:/tmp/.X11-unix:rw   houliangping bash
2. screen -dmS server python proxy_server.py 127.0.0.1 8080
3. su hou -c 'python proxy_client.py 127.0.0.1 8080'


