FROM ubuntu

# armhf amd64
ENV arch1=armhf

# armhf linx64
ENV arch2=arm7hf

RUN export uid=1000 gid=1000 && \
    mkdir -p /home/hou && \
    mkdir -p /etc/sudoers.d && \
    echo "hou:x:${uid}:${gid}:hou,,,:/home/hou:/bin/bash" >> /etc/passwd && \
    echo "hou:x:${uid}:" >> /etc/group && \
    echo "hou ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/hou && \
    chmod 0440 /etc/sudoers.d/hou && \
    chown ${uid}:${gid} -R /home/hou && \
    echo "export DISPLAY=:0" >> /etc/profile

RUN cd /home/hou && \
    sed -i 's/ports.ubuntu.com/mirrors.aliyun.com/' /etc/apt/sources.list && \
    apt update && \
    apt install -y python2.7 python-pip tcpdump python-lxml wget vim iproute2 net-tools screen && \
    wget https://raw.githubusercontent.com/paypal/nemo-firefox-profile/master/example/resources/modify_headers-0.7.1.1-fx.xpi && \
    pip install beautifulsoup4 scapy scapy-http requests selenium

# arm7hf linx64 linux32
RUN wget https://github.com/mozilla/geckodriver/releases/download/v0.15.0/geckodriver-v0.15.0-${arch2}.tar.gz -O geck.tar.gz && \
    tar -xzvf geck.tar.gz && \
    mv geckodriver /usr/local/bin/

RUN apt install -y libxt6 libxrender1 libxext6 libx11-6 libstartup-notification0 libpangocairo-1.0-0 libpango-1.0-0 libgtk2.0-0 libgdk-pixbuf2.0-0 libfreetype6 libfontconfig1 libdbus-glib-1-2 libcairo2 libatk1.0-0 libasound2 lsb-release && \
    wget http://mirrors.aliyun.com/ubuntu-ports/pool/main/f/firefox/firefox_45.0.2+build1-0ubuntu1_${arch1}.deb -O firefox.deb && \
    dpkg -i firefox.deb

CMD sleep 1000d

RUN apt install -y ttf-wqy-microhei

COPY proxy_client.py /home/hou/
COPY proxy_server.py /home/hou/
COPY run.sh /home/hou/

WORKDIR /home/hou
