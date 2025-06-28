FROM ubuntu:18.04 AS bts-container

ENV NO_ARCH_OPT 1
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get -y install --no-install-suggests \
    build-essential libgsm1-dev libusb-1.0-0-dev autoconf \
    wget subversion nano apache2 automake cmake php libapache2-mod-php iptables software-properties-common \
    git doxygen bash net-tools tcpdump iproute2 telnet  \
    libboost-system-dev libboost-test-dev libboost-thread-dev  \
    cmake make gcc g++ pkg-config libfftw3-dev libmbedtls-dev libsctp-dev libyaml-cpp-dev libgtest-dev libzmq3-dev \
    libboost-program-options-dev libconfig++-dev libsctp-dev gnuradio libpcsclite-dev libdw-dev pcscd pcsc-tools \
    nano #libqwt-qt5-dev qtbase5-dev qtmultimedia5-dev libqt5multimediawidgets5 libqt5multimedia5 libqt5multimedia5-pluginslibqt4multimedia4 libqt4multimedia4-plugins

RUN add-apt-repository universe && apt-get update && apt-get -y install --no-install-suggests libuhd-dev libuhd003.010.003 uhd-host

RUN apt-get update && apt-get -y install --no-install-suggests liblimesuite-dev soapysdr-module-lms7 soapysdr-tools uhd-soapysdr 


#RUN cd /usr/src/ && git clone https://github.com/pothosware/SoapyUHD.git
RUN cd /usr/src/ && git clone https://github.com/yatevoip/yate.git && cd yate && git reset --hard 94298ebbf1294740e38b24f111f24777f5e9163d #svn checkout http://voip.null.ro/svn/yate/trunk yate
RUN cd /usr/src/ && git clone https://github.com/grant-h/YateBTS-USRP.git yatebts #https://github.com/yatevoip/yatebts.git #svn checkout http://voip.null.ro/svn/yatebts/trunk yatebts
RUN mkdir -p /usr/local/share/yate/nipc_web/ && cd /usr/local/share/yate/nipc_web/ && git clone https://github.com/yatevoip/ansql.git


#RUN cd /usr/src/SoapyUHD/ && mkdir build && cd build && cmake .. && make -j4 && make install
RUN echo 'export UHD_MODULE_PATH=/opt/lib/uhd/modules'  | tee --append /etc/environment
RUN . /etc/environment


RUN cd /usr/src/yate/ && ./autogen.sh && ./configure && make && make install
RUN echo "export LD_LIBRARY_PATH=/usr/local/lib/:$LD_LIBRARY_PATH"  | tee --append /etc/environment
RUN . /etc/environment


#RUN ls -alh /usr/local/share/yate/
RUN cd /usr/src/yatebts/ && ./autogen.sh && ./configure && make install

RUN ln -s /usr/local/share/yate/nipc_web/ /var/www/html/nipc
RUN chmod -R a+rw /usr/local/etc/yate


RUN apt-get update && apt-get -y install --no-install-suggests build-essential checkinstall libreadline-gplv2-dev \
	libncursesw5-dev libssl-dev libsqlite3-dev tk-dev libgdbm-dev libc6-dev \
	libbz2-dev openssl libffi-dev

RUN cd /usr/src/ && curl -O https://www.python.org/ftp/python/3.9.2/Python-3.9.2.tgz && tar -xzf Python-3.9.2.tgz
RUN cd /usr/src/Python-3.9.2/ && ./configure --enable-shared --enable-optimizations --prefix=/usr LDFLAGS="-Wl,--rpath=/usr/lib" && make altinstall

RUN apt-get update && apt-get -y install --no-install-suggests \
	python3-setuptools \
	python3-pycryptodome \
	python3-pyscard \
	python3-pip

RUN rm /usr/bin/python3 && ln -s python3.9 /usr/bin/python3

RUN ln -s /usr/share/pyshared/lsb_release.py /usr/lib/python3.9/site-packages/lsb_release.py

RUN /usr/bin/python3.9 -m pip install --upgrade pip


RUN cd /usr/src/ && git clone https://gitea.osmocom.org/sim-card/pysim.git # && cd pysim && git reset --hard a437d11135e66b7645021c606c8b2099358302c8
RUN cd /usr/src/ && git clone https://gitea.osmocom.org/osmocom/pyosmocom.git
RUN cd /usr/src/pyosmocom/ && python3.9 -m pip install ./
RUN cd /usr/src/pysim/ && python3.9 -m pip install ./


ARG S6_OVERLAY_VERSION=3.2.1.0
RUN apt-get update && apt-get install -y xz-utils
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-noarch.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-symlinks-noarch.tar.xz
ENTRYPOINT ["/init"]

COPY rootfs /
#COPY config.php /var/www/html/nipc/
RUN chmod -R +x /etc/s6-overlay/scripts/

RUN mkdir -p /config/yate

ENV TERM xterm
EXPOSE 80/tcp
#ENTRYPOINT [ "bash" ]
#ENTRYPOINT [ "/lib/systemd/systemd" ]
