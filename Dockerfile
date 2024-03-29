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
	
FROM centos/systemd
MAINTAINER Bryan Rodriguez <email@bryanrodriguez.com>

ARG WOK_VER=2.5.0
ARG KIMCHI_VER=2.5.0

WORKDIR /tmp
RUN yum update -y -v && yum install -y wget && yum clean all && rm -rf /var/cache/yum
COPY --from=builder /opt/app-root/src/wok/rpm/RPMS/noarch/wok-$WOK_VER-0.el7.noarch.rpm wok.el7.noarch.rpm
COPY --from=builder /opt/app-root/src/kimchi/rpm/RPMS/noarch/kimchi-$KIMCHI_VER-0.el7.noarch.rpm kimchi.el7.noarch.rpm
RUN wget -O gingerbase.el7.noarch.rpm http://kimchi-project.github.io/gingerbase/downloads/latest/ginger-base.el7.centos.noarch.rpm
RUN wget -O ginger.el7.noarch.rpm http://kimchi-project.github.io/ginger/downloads/latest/ginger.el7.centos.noarch.rpm

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
		sudo \
	&& yum clean all \
	&& rm -rf /var/cache/yum

RUN yum install -y \
		wok.el7.noarch.rpm \
		kimchi.el7.noarch.rpm \
		gingerbase.el7.noarch.rpm \
		ginger.el7.noarch.rpm \
    && rm -f *.rpm \
    && systemctl enable wokd.service
	
RUN sed -i 's/udev_sync = 1/udev_sync = 0/g' /etc/lvm/lvm.conf && sed -i 's/udev_rules = 1/udev_rules = 0/g' /etc/lvm/lvm.conf
	
COPY prep-init /bin/prep-init
	
WORKDIR /

ENV USERNAME 'wok-admin'
ENV HASHPASS '$6$JQla14fc5vWHfON9$j4Z7ODZcQpP4UHCLE2kMDjVVe6MS70VTgIjS10mVvfHylIRnFRjJiRNuP70rLTrDW5twYp2Z.IMUwFRTL.QxU1'

EXPOSE 8001 8010

ENTRYPOINT ["/bin/prep-init"]
CMD []
