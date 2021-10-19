#!/bin/sh

# Required environment variables
# SAMBA_DC_REALM - Samba Realm
# SAMBA_DC_ACTION - Action to take (provision or join)
# SAMBA_DC_MASTER - Only required or used during domain join. IP Address of existing DC to join.
# SAMBA_DC_ADMIN_PASSWD - Administrator password (only used to provision or join domain). If not specified, will randomly generate. Must be correct to join.

# Optional environment variables
# SAMBA_DC_DNS_FORWARDER - IP address to forward DNS requests to (accepts space separated list)
# SAMBA_OPTIONS - Raw options to be passed to samba-tool during provision/join
# SAMBA_DC_DOMAIN - Samba AD Domain shortname. Set to leftmost part of SAMBA_DC_REALM if unspecified.

set -e

COMMAND=ash

# Add $COMMAND if needed
if [ "${1:0:1}" = "-" ]
then
  set -- $COMMAND "$@"
fi

info () {
  echo "[INFO] $@"
}

if [ ! -f /samba/etc/smb.conf ]; then

  : "${SAMBA_DC_REALM:?SAMBA_DC_REALM must be set}"
  : "${SAMBA_DC_ACTION:?SAMBA_DC_ACTION must be set}"

  SAMBA_DC_ADMIN_PASSWD=${SAMBA_DC_ADMIN_PASSWD:-`(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c20; echo) 2>/dev/null`}
  info "Samba Administrator password set to: ${SAMBA_DC_ADMIN_PASSWD}"

  SAMBA_OPTIONS=${SAMBA_OPTIONS:-}

  SAMBA_DC_DOMAIN=${SAMBA_DC_DOMAIN:-${SAMBA_DC_REALM%%.*}}
  info "Samba Domain shortname set to: ${SAMBA_DC_DOMAIN}"
  mkdir -p /samba/etc /samba/lib /samba/log /samba/shares
  case "${SAMBA_DC_ACTION}" in
    "join")
      : "${SAMBA_DC_MASTER:?SAMBA_DC_MASTER must be set to join a domain}"
      info "${SAMBA_DC_DOMAIN} - Begin Domain Joining"
      samba-tool domain join "${SAMBA_DC_REALM}" "DC" \
        --server="${SAMBA_DC_MASTER}" \
        --dns-backend="SAMBA_INTERNAL" \
        --username="Administrator" \
        --password="${SAMBA_DC_ADMIN_PASSWD}" \
        --workgroup="${SAMBA_DC_DOMAIN}" \
        $SAMBA_OPTIONS \
        --option="bind interfaces only"="yes" \
        --option="dns forwarder"="${SAMBA_DC_DNS_FORWARDER}" \
        --option="idmap_ldb:use rfc2307"="yes"
      info "${SAMBA_DC_DOMAIN} - Domain Joining Successful"
      echo "# ADD YOUR FOLDERS SHARES HERE #
      
      # SET PERMISSIONS OF FOLDER WITH THIS COMMAND:
      docker exec -it dc chown root:\"Domain Admins\" /samba/shares/FOLDER
      " > /samba/shares/README.txt      
      ;;
    "provision")
      info "${SAMBA_DC_DOMAIN} - Begin Domain Provisioning"
      samba-tool domain provision --domain="${SAMBA_DC_DOMAIN}" \
        --adminpass="${SAMBA_DC_ADMIN_PASSWD}" \
        --server-role=dc \
        --realm="${SAMBA_DC_REALM}" \
        --dns-backend="SAMBA_INTERNAL" \
        --use-rfc2307 \
        $SAMBA_OPTIONS \
        --option="interfaces=lo $SAMBA_INTERFACE" \
        --option="bind interfaces only=yes" \
        --option="dns forwarder"="${SAMBA_DC_DNS_FORWARDER}"
      info "${SAMBA_DC_DOMAIN} - Domain Provisioning Successful"
      echo "# ADD YOUR FOLDERS SHARES HERE #
     
      # SET PERMISSIONS OF FOLDER WITH THIS COMMAND:
      docker exec -it pdc chown root:\"Domain Admins\" /samba/shares/FOLDER
      " > /samba/shares/README.txt
      ;;
    *)
      : "${SAMBA_ERROR_OUT:?SAMBA_DC_ACTION must be either 'provision' or 'join'}"
      ;;
  esac
fi

if [ "$1" = 'samba' ]
then
  exec samba -i < /dev/null
fi

# If we get here, the user wants to run their own command. Let them.
exec "$@"
