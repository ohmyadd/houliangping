# docker run -d --name hou --net=host -v /tmp/.X11-unix/:/tmp/.X11-unix -e DISPLAY=:0 --privileged houliangping

if [ "$1" == "client" ];then
  su hou -c 'python proxy_client.py 127.0.0.1 8080'
fi

if [ "$1" == "server" ];then
  screen -dmS server python proxy_server.py 127.0.0.1 8080
fi

