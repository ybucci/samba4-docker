FROM centos:centos8


# ARG DEBIAN_FRONTEND=noninteractive
# RUN DEP_MODULES="acl apt-utils attr autoconf bind9utils binutils bison build-essential ccache chrpath curl debhelper dnsutils docbook-xml docbook-xsl flex gcc gdb git glusterfs-common gzip heimdal-multidev hostname htop krb5-config krb5-kdc krb5-user language-pack-en lcov libacl1-dev libarchive-dev libattr1-dev libavahi-common-dev libblkid-dev libbsd-dev libcap-dev libcephfs-dev libcups2-dev libdbus-1-dev libglib2.0-dev libgnutls28-dev libgpgme11-dev libicu-dev libjansson-dev libjs-jquery libjson-perl libkrb5-dev libldap2-dev liblmdb-dev libncurses5-dev libpam0g-dev libparse-yapp-perl libpcap-dev libpopt-dev libreadline-dev libsystemd-dev libtasn1-bin libtasn1-dev libtracker-sparql-2.0-dev libunwind-dev lmdb-utils locales lsb-release make mawk mingw-w64 patch perl perl-modules pkg-config procps psmisc python3 python3-cryptography python3-dbg python3-dev python3-dnspython python3-gpg python3-iso8601 python3-markdown python3-matplotlib python3-pexpect python3-pyasn1 python3-setproctitle rng-tools rsync sed sudo tar tree uuid-dev wget xfslibs-dev xsltproc zlib1g-dev" && apt-get update && apt-get install -y $DEP_MODULES && apt-get -y autoremove && apt-get -y autoclean && apt-get -y clean
RUN yum update -y && yum install -y dnf-plugins-core && yum install -y epel-release
RUN yum -v repolist all
RUN yum config-manager --set-enabled PowerTools -y || \
    yum config-manager --set-enabled powertools -y
RUN yum config-manager --set-enabled Devel -y || \
    yum config-manager --set-enabled devel -y
RUN yum update -y
RUN yum install -y \
    --setopt=install_weak_deps=False \
    "@Development Tools" \
    acl \
    attr \
    autoconf \
    avahi-devel \
    bind-utils \
    binutils \
    bison \
    ccache \
    chrpath \
    cups-devel \
    curl \
    dbus-devel \
    docbook-dtds \
    docbook-style-xsl \
    flex \
    gawk \
    gcc \
    gdb \
    git \
    glib2-devel \
    glibc-common \
    glibc-langpack-en \
    glusterfs-api-devel \
    glusterfs-devel \
    gnutls-devel \
    gpgme-devel \
    gzip \
    hostname \
    htop \
    jansson-devel \
    keyutils-libs-devel \
    krb5-devel \
    krb5-server \
    krb5-workstation \
    libacl-devel \
    libarchive-devel \
    libattr-devel \
    libblkid-devel \
    libbsd-devel \
    libcap-devel \
    libcephfs-devel \
    libicu-devel \
    libpcap-devel \
    libtasn1-devel \
    libtasn1-tools \
    libtirpc-devel \
    libunwind-devel \
    libuuid-devel \
    libxslt \
    lmdb \
    lmdb-devel \
    make \
    mingw64-gcc \
    ncurses-devel \
    openldap-devel \
    pam-devel \
    patch \
    perl \
    perl-Archive-Tar \
    perl-ExtUtils-MakeMaker \
    perl-JSON \
    perl-Parse-Yapp \
    perl-Test-Simple \
    perl-generators \
    perl-interpreter \
    pkgconfig \
    popt-devel \
    procps-ng \
    psmisc \
    python3 \
    python3-cryptography \
    python3-devel \
    python3-dns \
    python3-gpg \
    python3-iso8601 \
    python3-libsemanage \
    python3-markdown \
    python3-policycoreutils \
    python3-pyasn1 \
    python3-setproctitle \
    quota-devel \
    readline-devel \
    redhat-lsb \
    rng-tools \
    rpcgen \
    rpcsvc-proto-devel \
    rsync \
    sed \
    sudo \
    systemd-devel \
    tar \
    tracker-devel \
    tree \
    wget \
    which \
    xfsprogs-devel \
    yum-utils \
    zlib-devel

RUN yum clean all    

RUN wget https://download.samba.org/pub/samba/samba-4.15.0.tar.gz
RUN tar -xvf samba-4.15.0.tar.gz && cd samba-4.15.0 && ./configure --prefix /usr --enable-fhs --sysconfdir=/etc --localstatedir=/var --with-privatedir=/var/lib/samba/private --with-piddir=/var/run/samba --with-automount --datadir=/usr/share --with-lockdir=/var/run/samba --with-statedir=/var/lib/samba --with-cachedir=/var/cache/samba && make -j4 && make install && rm -rf /samba-4.15.0*

RUN ln -s /etc/samba /samba/etc  \
  && ln -s /var/lib/samba /samba/lib  \
  && ln -s /var/log/samba /samba/log 

COPY nsswitch.conf /etc/nsswitch.conf
RUN ln -s /usr/lib/libnss_winbind.so.2 /lib64/
RUN ln -s /lib64/libnss_winbind.so.2 /lib64/libnss_winbind.so
RUN ldconfig

# ENV PATH=/usr/local/samba/bin:/usr/local/samba/sbin:$PATH

# VOLUME ["/var/lib/samba", "/etc/samba"]

VOLUME [ "/samba" ]

ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["samba"]

# FROM alpine:latest
# MAINTAINER AdamRushad <2429990+adamrushad@users.noreply.github.com>

# #Install
# RUN apk add --no-cache samba-dc \
#   # Remove default config data, if any
#   && rm -rf /etc/samba \
#   && rm -rf /var/lib/samba \
#   && rm -rf /var/log/samba \
#   # Create needed symbolic links
#   && ln -s /samba/etc /etc/samba \
#   && ln -s /samba/lib /var/lib/samba \
#   && ln -s /samba/log /var/log/samba

# #Ports
# EXPOSE 37/udp \
#   53 \
#   88 \
#   123/udp \
#   135/tcp \
#   137/udp \
#   138/udp \
#   139 \
#   389 \
#   445 \
#   464 \
#   636/tcp \
#   49152-65535/tcp \
#   3268/tcp \
#   3269/tcp

# #Volume config
# VOLUME ["/samba"]

# # Entrypoint
# COPY ./entrypoint.sh /
# ENTRYPOINT ["/entrypoint.sh"]
# CMD ["samba"]

# ARG BUILD_DATE
# ARG VCS_REF
# ARG VERSION
# LABEL org.label-schema.build-date=$BUILD_DATE \
#   org.label-schema.name="Samba AD DC - Alpine" \
#   org.label-schema.description="Provides a Docker image for Samba 4 DC on Alpine Linux." \
#   org.label-schema.url="https://github.com/adamrushad/samba4-ad-dc/" \
#   org.label-schema.vcs-ref=$VCS_REF \
#   org.label-schema.vcs-url="https://github.com/adamrushad/samba4-ad-dc" \
#   org.label-schema.version=$VERSION \
#   org.label-schema.schema-version="1.0"
