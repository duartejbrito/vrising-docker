FROM ubuntu:20.04
LABEL maintainer="Duarte 'SyTeR' Brito"

VOLUME ["/mnt/vrising/server", "/mnt/vrising/data"]

ARG DEBIAN_FRONTEND="noninteractive"

# create user and set PGID/PUID
# RUN groupadd -g "${PGID:-0}" -o vrising && \
#   useradd -g "${PGID:-0}" -u "${PUID:-0}" -o --create-home vrising

# install common packages
RUN apt update && \
  apt-get install -y wget unzip curl jq rsync

# install wine xvfb
RUN dpkg --add-architecture i386 && \
  wget -nc https://dl.winehq.org/wine-builds/winehq.key && \
  mv winehq.key /usr/share/keyrings/winehq-archive.key && \
  wget -nc https://dl.winehq.org/wine-builds/ubuntu/dists/focal/winehq-focal.sources && \
  mv winehq-focal.sources /etc/apt/sources.list.d/ && \
  apt update && \
  apt install -y winehq-stable xvfb

# install steamcmd
RUN mkdir -p /root/.wine/drive_c/steamcmd && \
  wget https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip -P /root/.wine/drive_c/steamcmd/ && \
  cd /root/.wine/drive_c/steamcmd/ && \
  unzip steamcmd.zip

# cleanup
RUN rm -rf /var/lib/apt/lists/* && \
  apt clean && \
  apt autoremove -y

# copy scripts
COPY entrypoint /usr/local/sbin/
COPY defaults /usr/local/etc/vrising/
COPY common /usr/local/etc/vrising/

# permissions
RUN chmod +x /usr/local/sbin/entrypoint

CMD ["/usr/local/sbin/entrypoint"]