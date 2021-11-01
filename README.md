# Samba4 AD-DC docker container

This docker container runs Samba4 as an Active Directory Domain Controller.

The first time you start the container, samba-tool will be invoked to set it up using the supplied [environment variables](#environment-variables).
After set is complete, the container will continue starting to get the DC up and running.

Automation of deployment with Ansible: https://github.com/YuriBucci2/samba4-docker-ansible

See the following examples on how to start/setup the DC. 

## Exemples 

### Domain Provision

```bash
docker run -d -it  \
    -e SAMBA_DC_REALM="contoso.local"  \
    -e SAMBA_DC_ADMIN_PASSWD="Password1!" \
    -e SAMBA_DC_ACTION="provision" \
    -e SAMBA_DC_DOMAIN="CONTOSO" \
    -e SAMBA_INTERFACE="enp0s3" \
    -v /etc/timezone:/etc/timezone:ro \
    -v /etc/localtime:/etc/localtime:ro \
    -v /var/lib/samba:/var/lib/samba \
    -v /etc/samba:/etc/samba \
    -v /var/log/samba:/var/log/samba \
    -v ${PWD}/samba/shares:/samba/shares \
    --net host --privileged \
    -h servidor-pdc.contoso.local -P \
    --restart=unless-stopped \
    --name pdc \
    yuribucci/samba4-dc:1.0.0_4.14.8
```

### Domain Join

```bash
docker run -d -it  \
    -e SAMBA_DC_REALM="contoso.local"  \
    -e SAMBA_DC_ADMIN_PASSWD="Password1!" \
    -e SAMBA_DC_ACTION="join" \
    -e SAMBA_DC_DOMAIN="CONTOSO" \
    -e SAMBA_DC_MASTER="192.168.15.24" \
    -e SAMBA_INTERFACE="enp0s3" \
    -v /etc/timezone:/etc/timezone:ro \
    -v /etc/localtime:/etc/localtime:ro \
    -v /var/lib/samba:/var/lib/samba \
    -v /etc/samba:/etc/samba \
    -v /var/log/samba:/var/log/samba \
    -v ${PWD}/samba/shares:/samba/shares \
    --net host --privileged \
    -h servidor-dc.contoso.local -P \
    --restart=unless-stopped \
    --name dc \
    yuribucci/samba4-dc:1.0.0_4.14.8
```

## Environment variables

The following environment variables are all used as part of the DC setup process.
If the DC has been setup, none of htese variables have any effect on the container.

- `SAMBA_DC_REALM` (*required*) The realm (FQDN) for the domain. (e.q. `samdom.example.com`).
- `SAMBA_DC_ACTION` (*required*) The action to take for setup. Must either be `provision` or `join`.
- `SAMBA_DC_MASTER` (*required for joining*) The master DC to join. Should be an IP address.
- `SAMBA_DC_ADMIN_PASSWD` (*required for joining*) The Administrator password for the domain. Will randomly generate if not specified, but *must* be correct to join an existing domain.
- `SAMBA_INTERFACE` (*required*) Interface of host who will be used
- `SAMBA_DC_DOMAIN` (*optional*) Short name for the domain to create/join. Set to leftmost part of `SAMBA_DC_REALM` if unspecified.
