FROM ubuntu:20.04
LABEL maintainer="Duarte 'SyTeR' Brito"

VOLUME ["/mnt/vrising/server", "/mnt/vrising/data"]

ARG DEBIAN_FRONTEND="noninteractive"
RUN apt update -y && \
    apt-get upgrade -y && \
    apt-get install -y  apt-utils && \
    apt-get install -y  software-properties-common tzdata && \
    add-apt-repository multiverse && \
    dpkg --add-architecture i386 && \
    apt update -y && \
    apt-get upgrade -y 

RUN useradd -m steam && cd /home/steam && \
    echo steam steam/question select "I AGREE" | debconf-set-selections && \
    echo steam steam/license note '' | debconf-set-selections && \
    apt purge steam steamcmd && \
    apt install -y gdebi-core libgl1-mesa-glx:i386 wget && \
    apt install -y steam steamcmd && \
    ln -s /usr/games/steamcmd /usr/bin/steamcmd    

RUN apt install -y wine 

RUN apt install -y xserver-xorg xvfb

RUN apt install -y jq

RUN rm -rf /var/lib/apt/lists/* && \
    apt clean && \
    apt autoremove -y

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
CMD ["/entrypoint.sh"]