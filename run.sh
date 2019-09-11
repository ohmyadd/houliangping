if [ "$1" == "client" ];then
  su hou -c 'export DISPLAY=:0; python proxy_client.py 127.0.0.1 8080'
fi

if [ "$1" == "server" ];then
  screen -dmS server python proxy_server.py 127.0.0.1 8080
fi
