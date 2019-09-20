FROM ubuntu

# arm7hf linux64
ENV arch1=linux64

# armhf amd64
ENV arch2=amd64


RUN export uid=1000 gid=1000 && \
    mkdir -p /home/hou && \
    mkdir -p /etc/sudoers.d && \
    echo "hou:x:${uid}:${gid}:hou,,,:/home/hou:/bin/bash" >> /etc/passwd && \
    echo "hou:x:${uid}:" >> /etc/group && \
    echo "hou ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/hou && \
    chmod 0440 /etc/sudoers.d/hou && \
    chown ${uid}:${gid} -R /home/hou && \
    echo "export DISPLAY=:0" >> /etc/profile && \
    sed -i s@/archive.ubuntu.com/@/mirrors.aliyun.com/@g /etc/apt/sources.list && \
    apt update && \
    apt install -y python2.7 python-pip tcpdump python-lxml wget vim iproute2 net-tools screen ttf-wqy-microhei && \
    pip install beautifulsoup4 scapy scapy-http requests selenium -i https://pypi.douban.com/simple

# arm7hf linx64 linux32
RUN cd /home/hou && \
    wget https://github.com/mozilla/geckodriver/releases/download/v0.15.0/geckodriver-v0.15.0-${arch1}.tar.gz -O geck.tar.gz && \
    wget https://raw.githubusercontent.com/paypal/nemo-firefox-profile/master/example/resources/modify_headers-0.7.1.1-fx.xpi && \
    tar -xzvf geck.tar.gz && \
    mv geckodriver /usr/local/bin/ && \
    rm geck.tar.gz

RUN apt install -y libxt6 libxrender1 libxext6 libx11-6 libstartup-notification0 libpangocairo-1.0-0 libpango-1.0-0 libgtk2.0-0 libgdk-pixbuf2.0-0 libfreetype6 libfontconfig1 libdbus-glib-1-2 libcairo2 libatk1.0-0 libasound2 lsb-release && \
    wget \
    http://mirrors.aliyun.com/ubuntu/pool/main/f/firefox/firefox_45.0.2+build1-0ubuntu1_amd64.deb \
    #http://mirrors.aliyun.com/ubuntu-port/pool/main/f/firefox/firefox_45.0.2+build1-0ubuntu1_armhf.deb \
    -O firefox.deb && \
    dpkg -i firefox.deb && \
    rm firefox.deb

WORKDIR /home/hou

CMD sleep 1000d

COPY proxy_client.py /home/hou/
COPY proxy_server.py /home/hou/
COPY run.sh /home/hou/
