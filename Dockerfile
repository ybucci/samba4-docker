FROM centos:centos8

ARG SAMBA_VERSION=4.14.8

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
    bind \
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
    zlib-devel \
    supervisor

RUN yum clean all    

RUN wget https://download.samba.org/pub/samba/stable/samba-$SAMBA_VERSION.tar.gz
RUN tar -xvf samba-$SAMBA_VERSION.tar.gz && cd samba-$SAMBA_VERSION && ./configure --prefix /usr --enable-fhs --sysconfdir=/etc --localstatedir=/var --with-privatedir=/var/lib/samba/private --with-piddir=/var/run/samba --with-automount --datadir=/usr/share --with-lockdir=/var/run/samba --with-statedir=/var/lib/samba --with-cachedir=/var/cache/samba && make -j4 && make install && rm -rf /samba-$SAMBA_VERSION*

COPY nsswitch.conf /etc/nsswitch.conf
COPY named.conf /etc/named.conf
RUN chown named:named /etc/named.conf
RUN echo 'OPTIONS="-4"' >> /etc/sysconfig/named

RUN ln -s /usr/lib/libnss_winbind.so.2 /lib64/
RUN ln -s /lib64/libnss_winbind.so.2 /lib64/libnss_winbind.so
RUN ldconfig

RUN rm -rf /etc/samba/smb.conf

ADD entrypoint.sh /entrypoint.sh
COPY supervisord.conf /etc/supervisord.d/supervisord.conf
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["samba"]