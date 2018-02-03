FROM centos:7

LABEL org.label-schema.vcs-url="https://github.com/giovtorres/docker-centos7-slurm" \
      org.label-schema.docker.cmd="docker run -it -h ernie giovtorres/docker-centos7-slurm:latest" \
      org.label-schema.name="docker-centos7-slurm" \
      org.label-schema.description="Slurm All-in-one Docker container on CentOS 7" \
      maintainer="Giovanni Torres"

ARG SLURM_VERSION=17.11.2
ARG SLURM_DOWNLOAD_MD5=9c8dcc1737a36ab859612d64ec389847
ARG SLURM_DOWNLOAD_URL=https://download.schedmd.com/slurm/slurm-"$SLURM_VERSION".tar.bz2

RUN yum makecache fast \
    && yum -y install epel-release \
    && yum -y install \
        wget \
        bzip2 \
        perl \
        gcc \
        gcc-c++\
        vim-enhanced \
        git \
        make \
        munge \
        munge-devel \
        supervisor \
        python-devel \
        python-pip \
        python34 \
        python34-devel \
        python34-pip \
        mariadb-server \
        mariadb-devel \
        psmisc \
        bash-completion \
    && yum clean all \
    && rm -rf /var/cache/yum

RUN pip install Cython nose \
    && pip3 install Cython nose

RUN groupadd -r slurm && useradd -r -g slurm slurm

RUN set -x \
    && wget -O slurm.tar.bz2 "$SLURM_DOWNLOAD_URL" \
    && echo "$SLURM_DOWNLOAD_MD5" slurm.tar.bz2 | md5sum -c - \
    && mkdir /usr/local/src/slurm \
    && tar jxf slurm.tar.bz2 -C /usr/local/src/slurm --strip-components=1 \
    && rm slurm.tar.bz2 \
    && cd /usr/local/src/slurm \
    && ./configure --enable-debug --enable-front-end --prefix=/usr \
       --sysconfdir=/etc/slurm --with-mysql_config=/usr/bin \
       --libdir=/usr/lib64 \
    && make install \
    && install -D -m644 etc/cgroup.conf.example /etc/slurm/cgroup.conf.example \
    && install -D -m644 etc/slurm.conf.example /etc/slurm/slurm.conf.example \
    && install -D -m644 etc/slurm.epilog.clean /etc/slurm/slurm.epilog.clean \
    && install -D -m644 etc/slurmdbd.conf.example /etc/slurm/slurmdbd.conf.example \
    && install -D -m644 contribs/slurm_completion_help/slurm_completion.sh /etc/profile.d/slurm_completion.sh \
    && cd \
    && rm -rf /usr/local/src/slurm \
    && mkdir /etc/sysconfig/slurm \
        /var/spool/slurmd \
        /var/run/slurmd \
        /var/lib/slurmd \
        /var/log/slurm \
    && /sbin/create-munge-key

COPY slurm.conf /etc/slurm/slurm.conf
COPY slurmdbd.conf /etc/slurm/slurmdbd.conf
COPY supervisord.conf /etc/

VOLUME ["/var/lib/mysql", "/var/lib/slurmd", "/var/spool/slurmd", "/var/log/slurm"]

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["/bin/bash"]

RUN pip2 install -e git+https://github.com/wschuell/experiment_manager.git@origin/develop#egg=experiment_manager && pip3 install -e git+https://github.com/wschuell/experiment_manager.git@origin/develop#egg=experiment_manager
RUN yum install -y initscripts openssh-server openssh-clients passwd && ssh-keygen -A && systemctl enable sshd.service

RUN echo -e "dockerslurm\ndockerslurm\n" | passwd
