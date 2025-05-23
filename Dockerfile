FROM ubuntu:noble

LABEL maintainer="Bastian Kleinschmidt <debaschdi@googlemail.com>" \
      org.label-schema.docker.dockerfile="/Dockerfile" \
      org.label-schema.name="docker.new-telerising-api"

ARG DEPENDENCIES="sed curl wget git perl nano net-tools unzip ca-certificates gcc"

ENV USER_ID="99" \
    GROUP_ID="100" \
    TIMEZONE="Europe/Berlin" \
    UPDATE="yes" \
    DEBIAN_FRONTEND="noninteractive" \
    TERM=xterm \
    LANGUAGE="en_US.UTF-8" \
    LANG="en_US.UTF-8" \
    LC_ALL="en_US.UTF-8" \
    CLEANUP="/tmp/* /var/tmp/* /var/log/* /var/lib/apt/lists/* /var/lib/{apt,dpkg,cache,log}/ /var/cache/apt/archives /usr/share/doc/ /usr/share/man/ /usr/share/locale/ /root/.cpan /root/.cpanm"

COPY root/entrypoint /usr/local/sbin/entrypoint
COPY root/telerising.process /usr/local/bin/telerising.process
COPY root/telerising.update /usr/local/bin/telerising.update
COPY root/packages.cleanup /usr/local/sbin/packages.cleanup

RUN apt-get -qy update \
    ### tweak some apt & dpkg settngs
    && echo "APT::Install-Recommends "0";" >> /etc/apt/apt.conf.d/docker-noinstall-recommends \
    && echo "APT::Install-Suggests "0";" >> /etc/apt/apt.conf.d/docker-noinstall-suggests \
    && echo "Dir::Cache "";" >> /etc/apt/apt.conf.d/docker-nocache \
    && echo "Dir::Cache::archives "";" >> /etc/apt/apt.conf.d/docker-nocache \
    && echo "path-exclude=/usr/share/locale/*" >> /etc/dpkg/dpkg.cfg.d/docker-nolocales \
    && echo "path-exclude=/usr/share/man/*" >> /etc/dpkg/dpkg.cfg.d/docker-noman \
    && echo "path-exclude=/usr/share/doc/*" >> /etc/dpkg/dpkg.cfg.d/docker-nodoc \
    && echo "path-include=/usr/share/doc/*/copyright" >> /etc/dpkg/dpkg.cfg.d/docker-nodoc \
    ### install basic packages \
    && apt-get update \
    && apt-get install -qy apt-utils locales tzdata gpg\
    ### limit locale to en_US.UTF-8
    && sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen en_US.UTF-8 \
    && update-locale LANG=en_US.UTF-8 \
    && locale-gen --purge en_US.UTF-8 \
    ### run dist-upgrade
    && apt-get dist-upgrade -qy \
    ### install telerising dependencies
    && apt-get install -qy ${DEPENDENCIES} \
    ## configure System
    && update-ca-certificates --fresh \
    ### create necessary files/directories
    && mkdir -p /telerising \
    ### alter permissions
    && chmod +x /usr/local/sbin/entrypoint \
    && chmod +x /usr/local/bin/telerising.process \
    && chmod +x /usr/local/bin/telerising.update \
    && chmod +x /usr/local/sbin/packages.cleanup \
    ### cleanup
    && /usr/local/sbin/packages.cleanup

ENTRYPOINT [ "/usr/local/sbin/entrypoint" ]

VOLUME /telerising
EXPOSE 5000

