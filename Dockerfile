FROM centos/devtoolset-7-toolchain-centos7 as builder
MAINTAINER Bryan Rodriguez <email@bryanrodriguez.com>

ARG WOK_VER=2.5.0
ARG KIMCHI_VER=2.5.0
USER 0

RUN yum update -y && yum install -y \
	gcc \
	make \
	autoconf \
	automake \
	gettext-devel \
	git \
	rpm-build \
	libxslt \
	python-lxml

RUN git clone -b $WOK_VER --single-branch https://github.com/kimchi-project/wok.git && \
    cd wok && \
    ./autogen.sh --system && \
    make && \
    make rpm

RUN git clone -b $KIMCHI_VER --single-branch https://github.com/kimchi-project/kimchi.git && \
    cd kimchi && \
    ./autogen.sh --system && \
    make && \
    make rpm
	
RUN git clone --recursive https://github.com/kimchi-project/wok.git plugins && \
    cd plugins && \
    git submodule update --remote && \
    ./build-all.sh

FROM centos/systemd
MAINTAINER Bryan Rodriguez <email@bryanrodriguez.com>

ARG WOK_VER=2.5.0
ARG KIMCHI_VER=2.5.0

WORKDIR /tmp
COPY --from=builder /opt/app-root/src/wok/rpm/RPMS/noarch/wok-$WOK_VER-0.el7.noarch.rpm wok.el7.noarch.rpm
COPY --from=builder /opt/app-root/src/kimchi/rpm/RPMS/noarch/kimchi-$KIMCHI_VER-0.el7.noarch.rpm kimchi.el7.noarch.rpm

RUN yum update -y && yum install -y epel-release

RUN yum update -y -v && yum install -y \
		python-cherrypy \
		python-cheetah \
		PyPAM m2crypto \
		python-jsonschema \
		python-ldap \
		python-lxml \
		nginx \
		openssl \
		python-websockify \
		logrotate \
		fontawesome-fonts \
		python-psutil \
	&& yum clean all \
	&& rm -rf /var/cache/yum
	
RUN yum update -y -v && yum install -y \
		libvirt-python \
		libvirt \
		libvirt-daemon-config-network \
		qemu-kvm \
		python-ethtool \
		sos \
		python-ipaddr \
		nfs-utils \
		iscsi-initiator-utils \
		pyparted \
		python-libguestfs \
		libguestfs-tools \
		novnc \
		spice-html5 \
		python-configobj \
		python-magic \
		python-paramiko \
		python-pillow \
	&& yum clean all \
	&& rm -rf /var/cache/yum

RUN yum install -y \
		wok.el7.noarch.rpm \
		kimchi.el7.noarch.rpm && \
    rm -f wok.el7.noarch.rpm kimchi.el7.noarch.rpm && \
    systemctl enable wokd.service
	
RUN useradd wok-admin

WORKDIR /

EXPOSE 8001 8010

ENTRYPOINT ["/usr/sbin/init"]
CMD []
