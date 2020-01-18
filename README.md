
# docker-openvpn-qbittorrent

This project aims to provide a tightly encapsulated environment to run qBittorrent in. It runs in a docker-container with only one internet-facing network adapter: OpenVPN.

Some of its feaures are:

- qBittorrent Webinterface:
  This is where you interact with your bittorrent client.
- very strict strict iptable rules:
  Only the VPN interface allows incoming and outgoing connections. This includes torrent traffic and DNS
  An exception to this is the qBittorrent webinterface, which shall be accessible to the docker host. A IP subnet in CIDR notation can be provided to allow traffic from and to this subnet on the webinterface port
- DNS forced over VPN:
  DNS is blocked on the main network adapter. Meaning, that in order to use DNS, it must come from your VPN provider through a "push-config" through VPN. This should eliminate DNS leaks reliably
- Auto restart on VPN disconnect:
  When the VPN connection goes down, so does the docker-container. The provided `docker-compose` setup takes care, that the container is restarted.

## Disclaimer

This is free software, you are welcome to use it in any way you whish. It comes with no warranties whatsoever, I'm in no way liable if you do nasty things with it and get caught anyways. You shouldn't trust random software on the internet anyhow. I appreciate all contribution to this repository and hope to give you something usefull.

## Using this docker-image

The general procedure is this:

1) make sure, your VPN provider fullfills these criterias:
    - provides a .ovpn file for the connection
    - pushes a DNS configuration during the connection init. Look for something like this in your VPN log when you use the file outside of this container:
            <pre>PUSH: Received control message: 'PUSH_REPLY,ping 3,ping-restart 10,ifconfig 10.6.0.97 10.6.0.98,<b>dhcp-option DNS 95.179.135.181,dhcp-option DNS 138.68.175.3</b>,route-gateway 10.6.0.98,redirect-gateway def1'</pre>
2) clone this repo
3) place your .ovpn file in the `config/openvpn/` folder
4) add these lines at the end of your `.ovpn` file:

    ```bash
    auth-user-pass credentials.conf
    script-security 2
    up /etc/openvpn/client.up
    down /etc/openvpn/client.down
    ```

    They are needed to provide the auto restart and DNS functionality as well as make your VPN credentials accessible to the OpenVPN client inside the container.
5) generate a `vpn.env` file, that holds your VPN credentials like this:

    ```bash
    VPN_USERNAME=YourVpnUserNameGoesHere
    VPN_PASSWORD=YourVpnPasswordGoesHere
    ```

6) Change/review these items in the `docker-compose` file:

    - Environment Variables:
        - `LOCAL_SUBNET`: The subnet in CIDR notation, that shall be able to access the webinterface. e.g. `192.168.123.0/24`. This subnet can be set in the `network` section down below and must match.
        - `VPN_SERVER_IP`: IP adress of your VPN server. Go check your `.ovpn` file, it should be in there
        - `VPN_PROTO`: The protocol for the VPN conenction. Either `tcp` or `udp`
        - `WEBINTERFACE_PORT`: The port on which the qbittorrent webinterface runs.
    - Ports:
        - `127.0.0.1:8080:8080`: connection to the Web-Interface. The former `8080` indicates the port on the docker host. The later the port inside the container, must match the `WEBINTERFACE_PORT` Environment Variable
        - `8999:8999`: incoming torrent port. Must match, what is set up in the qBittorrent configuration.
        - `8999:8999/udp`: incoming torrent port. Must match, what is set up in the qBittorrent configuration.
    - Volumes:
        - `./config/openvpn/NL-Amsterdam1-CactusVPN-TCP.ovpn:/config/openvpn/profile.ovpn`: The mapping of your ovpn file into the container. To not change the part after the `:`
        - `./downloads/:/downloads`: Here, the downloads end up
        - `./config/qBittorrent/:/config/qBittorrent/config/`: This is where the qBittorrent configuration is stored. This image comes with sane defaults (dont forget to change the default WebInterface credentias, it is user: `admin` and password: `adminadmin`). The container has write access here, so all changes, that you do via the webinterface end up in this file.
    - Networks:
        - Here the local subnet is defined. A `30` subnet mask allows only two usable IP adresses, so it is "guaranteed", that the container gets one as well as the host and no other container can sneak into the same network and intercept your traffic there

7) build and run the docker image:
You can either pull the image from Dockerhub (it is built directly from this repository) or build it yourself. There are two `docker-compose` files, one for each scenario

- So, you trust me (you shouldn't) and want to pull the image?

        ``` bash
            docker-compose -f docker-compose.pull.yml up
        ```
- Or you can build it yourself

        ```
        docker-compose -f docker-compose.pull.yml up
        ```
        Should use your locally built image.

- Anyhow, afterwards, check that the container starts up and connects correctly

        ```bash
        docker-logs -f qbittorrent-vpn
        ```

        It should tell you `Initialization Sequence Completed` after a couple of seconds

1) Access the webinterface. Open `http://localhost:8080` (or another port if you have changed the default) in your browser. Login with admin/adminadmin and enjoy

2) Perform these steps for optimal peace of mind:

- change the password of the webinterface
- test with a well known torrent. e.g. ubuntu linux
- make a torrent leak check, e.g. at <http://checkmyip.torrentprivacy.com/> or <https://ipleak.net/>

## Closing thought and where to go from here

- Run container in non-privileged mode
Currently the container is running in privileged mode, which is usually not a good idea but is currently needed to create the VPN adapter. 
- HTTPS: The webinterface currently uses unencrypted HTTP. The attack surface is pretty limited though. The docker-network is occupied and the attacker would need to already have access to your machine.
- Test on Windows. Since Docker for windows is more or less a thing now, I'm curious to see if it works there but haven't tried yet. This image was tested on Linux and MacOS
