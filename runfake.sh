#! /bin/bash

set -x
iface=wlx00252236ef27

if [ "$1" == "run" ]; then
  mkdir -p /var/run/netns
  rm /var/run/netns/wpa
  rm /var/run/netns/open

  docker run -d --name wpa-wifi --restart=always --cap-add=NET_ADMIN -e IFACE=$iface -e SSID=wpa-wifi-range -e CHAN=11 -e ENC=wpa -e PASS=12345678 fakeap
  ln -s $(docker inspect wpa-wifi -f '{{.NetworkSettings.SandboxKey}}') /var/run/netns/wpa

  docker run -d --name open-wifi --restart=always --cap-add=NET_ADMIN -e IFACE=$iface -e SSID=open-wifi-range -e CHAN=6 fakeap
  ln -s $(docker inspect open-wifi -f '{{.NetworkSettings.SandboxKey}}') /var/run/netns/open
fi

if [ "$1" == "wpa" ]; then
  phy=$(cat /sys/class/net/$iface/phy80211/name)
  iw phy $phy set netns name wpa
  ip netns exec wpa ip link set $iface up
fi

if [ "$1" == "open" ]; then
  phy=$(cat /sys/class/net/$iface/phy80211/name)
  iw phy $phy set netns name open
  ip netns exec open ip link set $iface up
fi

if [ "$1" == "del" ]; then
  phy=$(ip netns exec wpa cat /sys/class/net/$iface/phy80211/name)
  ip netns exec wpa iw phy $phy set netns 1
  docker restart wpa-wifi -t 0
  rm /var/run/netns/wpa
  ln -s $(docker inspect wpa-wifi -f '{{.NetworkSettings.SandboxKey}}') /var/run/netns/wpa

  phy=$(ip netns exec open cat /sys/class/net/$iface/phy80211/name)
  ip netns exec open iw phy $phy set netns 1
  docker restart open-wifi -t 0
  rm /var/run/netns/open
  ln -s $(docker inspect open-wifi -f '{{.NetworkSettings.SandboxKey}}') /var/run/netns/open
fi
