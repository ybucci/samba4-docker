# Samba4 AD in Docker

This docker container runs Samba4 as an Active Directory Domain Controller PDC, DC and FileServer

The first time you start the container, samba-tool will be invoked to set it up using the supplied [environment variables](#environment-variables).
After set is complete, the container will continue starting to get the DC up and running.

Automation of deployment with Ansible: https://github.com/ybucci/samba4-docker-ansible

See the following examples on how to start/setup the DC and FileServer

### How to Domain Provision

- Pull the image

```bash
docker pull yuribucci/samba4-dc:1.0.0_4.17.0
```

- Edit resolv.conf and point DNS to your local server and search domain

```
search contoso.local
nameserver 192.168.18.130 # IP of your server
```

- Edit your hosts file and input all your servers of Samba4

```
192.168.18.130 server-pdc.contoso.local server-pdc
192.168.18.131 server-dc.contoso.local server-dc
```

- Run the image like above

```bash
docker run -d -it  \
    -e SAMBA_DC_REALM="contoso.local"  \
    -e SAMBA_DC_ADMIN_PASSWD="Password1!" \
    -e SAMBA_DC_ACTION="provision" \
    -e SAMBA_DC_DOMAIN="CONTOSO" \
    -e SAMBA_INTERFACE="eth1" \
    -v /etc/timezone:/etc/timezone:ro \
    -v /etc/localtime:/etc/localtime:ro \
    -v ${PWD}/samba/domain:/var/lib/samba \
    -v ${PWD}/samba/config:/etc/samba \
    -v ${PWD}/samba/logs:/var/log/samba \
    -v ${PWD}/samba/shares:/samba/shares \
    --net host --privileged \
    -h server-pdc.contoso.local -P \
    --restart=unless-stopped \
    --name samba-pdc \
    yuribucci/samba4-dc:1.0.0_4.17.0
```

### How to Domain DC Domain Join

- Pull the image

```bash
docker pull yuribucci/samba4-dc:1.0.0_4.17.0
```

- Edit resolv.conf and point DNS to your local server and search domain

```
search contoso.local
nameserver 192.168.18.130 # IP of your master server
```

- Edit your hosts file and input all your servers of Samba4

```
192.168.18.130 server-pdc.contoso.local server-pdc
192.168.18.131 server-dc.contoso.local server-dc
```

- Run the image like above


```bash
docker run -d -it  \
    -e SAMBA_DC_REALM="contoso.local"  \
    -e SAMBA_DC_ADMIN_PASSWD="Password1!" \
    -e SAMBA_DC_ACTION="join" \
    -e SAMBA_DC_DOMAIN="CONTOSO" \
    -e SAMBA_INTERFACE="eth1" \
    -v /etc/timezone:/etc/timezone:ro \
    -v /etc/localtime:/etc/localtime:ro \
    -v ${PWD}/samba/domain:/var/lib/samba \
    -v ${PWD}/samba/config:/etc/samba \
    -v ${PWD}/samba/logs:/var/log/samba \
    -v ${PWD}/samba/shares:/samba/shares \
    --net host --privileged \
    -h server-dc.contoso.local -P \
    --restart=unless-stopped \
    --name samba-dc \
    yuribucci/samba4-dc:1.0.0_4.17.0
```

- Wait for succesfull join, after that change the resolv.conf

```
search contoso.local
nameserver 192.168.18.131 # IP of your DC server
```

### How to Domain Member Join

- Pull the image

```bash
docker pull yuribucci/samba4-dc:1.0.0_4.17.0
```

- Edit resolv.conf and point DNS to your local server and search domain

```
search contoso.local
nameserver 192.168.18.130 # IP of your master server
nameserver 192.168.18.130 # IP of your DC server
```

- Edit your hosts file and input all your servers of Samba4

```
192.168.18.130 server-pdc.contoso.local server-pdc
192.168.18.131 server-dc.contoso.local server-dc
```

- Run the image like above


```bash
docker run -d -it  \
    -e SAMBA_DC_REALM="contoso.local"  \
    -e SAMBA_DC_ADMIN_PASSWD="Password1!" \
    -e SAMBA_DC_ACTION="member" \
    -e SAMBA_DC_DOMAIN="CONTOSO" \
    -e SAMBA_INTERFACE="eth1" \
    -v /etc/timezone:/etc/timezone:ro \
    -v /etc/localtime:/etc/localtime:ro \
    -v ${PWD}/samba/config:/etc/samba \
    -v ${PWD}/samba/logs:/var/log/samba \
    -v ${PWD}/samba/shares:/samba/shares \
    --net host --privileged \
    -h server-fs.contoso.local -P \
    --restart=unless-stopped \
    --name samba-fs \
    yuribucci/samba4-dc:1.0.0_4.17.0
```


## Environment variables



| Variable | Description |
| --- | --- |
| **SAMBA_DC_REALM** | The realm (FQDN) for the domain. (e.q. `contoso.local`) |
| **SAMBA_DC_ACTION** | The action to take for setup. Must either be `provision`,  `join` or `member` |
| **SAMBA_DC_ADMIN_PASSWD** | The Administrator password for the domain (e.q. `Password1!`) |
| **SAMBA_INTERFACE** | Network interface of host who will be used (e.q. `eth1`)|
| **SAMBA_DC_DOMAIN** | Short name for the domain to create/join (e.q. `CONTOSO`)|