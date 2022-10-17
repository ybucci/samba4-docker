#!/bin/sh

set -e

COMMAND=ash

SAMBA_IP_ADDRESS=`ip addr | grep $SAMBA_INTERFACE | grep inet | awk '{print $2}' | cut -f1 -d"/"`

# Add $COMMAND if needed
if [ "${1:0:1}" = "-" ]
then
  set -- $COMMAND "$@"
fi

info () {
  echo "[INFO] $@"
}

if [ ! -d /var/lib/samba/private ]; then
  mkdir /var/lib/samba/private
  chmod 700 /var/lib/samba/private
fi

if [ ! -d /var/lib/samba/bind-dns ]; then
  mkdir /var/lib/samba/bind-dns
  chmod 770 /var/lib/samba/bind-dns
fi

if [ ! -f /etc/samba/smb.conf ]; then

  : "${SAMBA_DC_REALM:?SAMBA_DC_REALM must be set}"
  : "${SAMBA_DC_ACTION:?SAMBA_DC_ACTION must be set}"

  SAMBA_DC_ADMIN_PASSWD=${SAMBA_DC_ADMIN_PASSWD:-`(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c20; echo) 2>/dev/null`}

  SAMBA_OPTIONS=${SAMBA_OPTIONS:-}

  SAMBA_DC_DOMAIN=${SAMBA_DC_DOMAIN:-${SAMBA_DC_REALM%%.*}}
  info "Samba Domain shortname set to: ${SAMBA_DC_DOMAIN}"
  case "${SAMBA_DC_ACTION}" in
    "join")
      info "${SAMBA_DC_DOMAIN} - Begin Domain Joining"
      samba-tool domain join "${SAMBA_DC_REALM}" DC \
        --dns-backend="BIND9_DLZ" \
        --username="Administrator" \
        --password="${SAMBA_DC_ADMIN_PASSWD}" \
        --workgroup="${SAMBA_DC_DOMAIN}" \
        --option="interfaces=lo $SAMBA_INTERFACE" \
        --option="bind interfaces only=yes"
      info "${SAMBA_DC_DOMAIN} - Domain Joining Successful"
      echo "# ADD YOUR FOLDERS SHARES HERE #
     
      # SET PERMISSIONS OF FOLDER WITH THIS COMMAND:
      docker exec -it samba-dc chown root:\"Domain Admins\" /samba/shares/FOLDER
      " > /samba/shares/README.txt
      rm -rf /etc/krb5.conf
      cp /var/lib/samba/private/krb5.conf /etc/krb5.conf
      chown root:named /etc/krb5.conf
      chown root:named /var/lib/samba/bind-dns -R
      mkdir /var/lib/samba/ntp_signd/
      chmod 0750 /var/lib/samba/ntp_signd/
      chown root.chrony /var/lib/samba/ntp_signd/       ;;
    "provision")
      info "${SAMBA_DC_DOMAIN} - Begin Domain Provisioning"
      samba-tool domain provision --domain="${SAMBA_DC_DOMAIN}" \
        --adminpass="${SAMBA_DC_ADMIN_PASSWD}" \
        --server-role=dc \
        --realm="${SAMBA_DC_REALM}" \
        --dns-backend="BIND9_DLZ" \
        --use-rfc2307 \
        --option="interfaces=lo $SAMBA_INTERFACE" \
        --option="bind interfaces only=yes"
      info "${SAMBA_DC_DOMAIN} - Domain Provisioning Successful"
      echo "# ADD YOUR FOLDERS SHARES HERE #
     
      # SET PERMISSIONS OF FOLDER WITH THIS COMMAND:
      docker exec -it samba-pdc chown root:\"Domain Admins\" /samba/shares/FOLDER
      " > /samba/shares/README.txt
      rm -rf /etc/krb5.conf
      cp /var/lib/samba/private/krb5.conf /etc/krb5.conf
      chown root:named /etc/krb5.conf
      chown root:named /var/lib/samba/bind-dns -R
      mkdir /var/lib/samba/ntp_signd/
      chmod 0750 /var/lib/samba/ntp_signd/
      chown root.chrony /var/lib/samba/ntp_signd/       ;;      
    "member")
      info "${SAMBA_DC_DOMAIN} - Begin Member Join"
      cp /entrypoint/krb5.conf /etc/krb5.conf
      SAMBA_DC_REALM_UPPER=$(echo $SAMBA_DC_REALM | tr 'a-z' 'A-Z')
      sed -i "s/CHANGE_ME/$SAMBA_DC_REALM_UPPER/g" /etc/krb5.conf
      samba-tool domain join "${SAMBA_DC_REALM}" MEMBER \
      --username="Administrator" \
      --password="${SAMBA_DC_ADMIN_PASSWD}" \
      --workgroup="${SAMBA_DC_DOMAIN}" \
      --option="interfaces=lo $SAMBA_INTERFACE" \
      --option="bind interfaces only=yes"      
      info "${SAMBA_DC_DOMAIN} - Domain Joining Successful"
      echo "# ADD YOUR FOLDERS SHARES HERE #
     
      # SET PERMISSIONS OF FOLDER WITH THIS COMMAND:

      docker exec -it samba-fs chown root:\"Domain Admins\" /samba/shares/FOLDER
      " > /samba/shares/README.txt
      ;;
    *)
      : "${SAMBA_ERROR_OUT:?SAMBA_DC_ACTION must be either 'provision', 'join' or 'member'}"
      ;;
  esac
fi

case "${SAMBA_DC_ACTION}" in
  "join")
    rm -rf /etc/krb5.conf
    cp /var/lib/samba/private/krb5.conf /etc/krb5.conf
    chown root:named /etc/krb5.conf
    chown root:named /var/lib/samba/bind-dns -R  
    cp /entrypoint/chrony.conf /etc/chrony.conf
    cp /entrypoint/supervisord-dc.conf /etc/supervisord.d/supervisord.conf
    ;;
  "provision")
    rm -rf /etc/krb5.conf
    cp /var/lib/samba/private/krb5.conf /etc/krb5.conf
    chown root:named /etc/krb5.conf
    chown root:named /var/lib/samba/bind-dns -R  
    cp /entrypoint/chrony.conf /etc/chrony.conf
    cp /entrypoint/supervisord-dc.conf /etc/supervisord.d/supervisord.conf 
    ;;
  "member")
    cp /entrypoint/chrony-fs.conf /etc/chrony.conf
    GET_HOSTS=$(cat /etc/hosts | awk '{print $2}' | egrep -iv "localhost|samba|#|^$|$(hostname)")
    for i in `echo $GET_HOSTS`; do if ! grep -qF "pool $i iburst" /etc/chrony.conf; then echo "pool $i iburst" >> /etc/chrony.conf; fi; done
    cp /entrypoint/supervisord-fs.conf /etc/supervisord.d/supervisord.conf
    cp /entrypoint/krb5.conf /etc/krb5.conf
    SAMBA_DC_REALM_UPPER=$(echo $SAMBA_DC_REALM | tr 'a-z' 'A-Z')
    sed -i "s/CHANGE_ME/$SAMBA_DC_REALM_UPPER/g" /etc/krb5.conf
    ;;
esac

if [ "$1" = 'samba' ]
then
  exec /usr/bin/supervisord -c /etc/supervisord.d/supervisord.conf
fi

# If we get here, the user wants to run their own command. Let them.
exec "$@"