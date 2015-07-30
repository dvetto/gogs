FROM debian:jessie
MAINTAINER David Personette <dperson@dperson.com>

# Install gogs
RUN export DEBIAN_FRONTEND='noninteractive' && \
    export URL='https://github.com/gogits/gogs/releases/download' && \
    export version='0.6.1' && \
    export sha256sum='ab4d8341d1c14e753914b68b3ec0c9b169c361123dcef541ff34' && \
    groupadd -r gogs && \
    useradd -r -d /opt/gogs/home -c 'Gogs' -m -g gogs gogs && \
    apt-get update -qq && \
    apt-get install -qqy --no-install-recommends ca-certificates curl unzip \
                dropbear git \
                $(apt-get -s dist-upgrade|awk '/^Inst.*ecurity/ {print $2}') &&\
    for i in dss rsa ecdsa; do rm -f /etc/dropbear/dropbear_${i}_host_key || :;\
                done && \
    dropbearkey -t dss -f /etc/dropbear/dropbear_dss_host_key && \
    dropbearkey -t rsa -s 4096 -f /etc/dropbear/dropbear_rsa_host_key && \
    dropbearkey -t ecdsa -s 521 -f /etc/dropbear/dropbear_ecdsa_host_key && \
    curl -LOC- -s $URL/v$version/linux_amd64.zip && \
    sha256sum linux_amd64.zip | grep -q "$sha256sum" && \
    (cd /opt; unzip -qq /linux_amd64.zip) && \
    mkdir -p /opt/gogs/custom/conf /opt/gogs/repositories || : && \
    /bin/echo -e 'RUN_MODE = prod\nRUN_USER = gogs\n\n[repository]' > \
                /opt/gogs/custom/conf/app.ini && \
    /bin/echo -e 'ROOT = /opt/gogs/repositories\n' >> \
                /opt/gogs/custom/conf/app.ini && \
    /bin/echo -e '[server]\nSSH_PORT = 2222\n' >> \
                /opt/gogs/custom/conf/app.ini && \
    /bin/echo -e '[database]\n; Either "mysql", "postgres", or "sqlite3"' >> \
                /opt/gogs/custom/conf/app.ini && \
    /bin/echo -e 'DB_TYPE = sqlite3\nPATH = data/gogs.db' >> \
                /opt/gogs/custom/conf/app.ini && \
    chown -Rh gogs. /opt/gogs && \
    apt-get purge -qqy ca-certificates curl unzip && \
    apt-get autoremove -qqy && apt-get clean -qqy && \
    rm -rf /tmp/* /var/lib/apt/lists/* linux_amd64.zip
COPY gogs.sh /usr/bin/

EXPOSE 2222 3000

VOLUME ["/etc/dropbear", "/opt/gogs/home", "/opt/gogs/custom", \
            "/opt/gogs/data", "/opt/gogs/log", "/opt/gogs/repositories"]

ENTRYPOINT ["gogs.sh"]
