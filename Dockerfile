FROM ubuntu:19.10

RUN apt update && \
    apt install -y curl strace vim dnsutils openvpn iptables telnet software-properties-common && \
    add-apt-repository ppa:qbittorrent-team/qbittorrent-stable && \
    apt update && \
    apt install -y qbittorrent-nox

VOLUME /downloads
VOLUME /config

WORKDIR /etc/openvpn

ADD src/ /etc/openvpn/

RUN chmod +x start.sh client.up client.down

CMD ["/bin/bash", "/etc/openvpn/start.sh"]