FROM ubuntu:16.04

USER root 

RUN apt-get -qq update && apt-get -qq install -y \
    unzip \
    xorg \
    wget && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


RUN mkdir /opt/mcr_install && \
    mkdir /opt/mcr && \
    wget -P /opt/mcr_install http://www.mathworks.com/supportfiles/downloads/R2018b/deployment_files/R2018b/installers/glnxa64/MCR_R2018b_glnxa64_installer.zip && \
    unzip -q /opt/mcr_install/MCR_R2018b_glnxa64_installer.zip -d /opt/mcr_install && \
    /opt/mcr_install/install -destinationFolder /opt/mcr -agreeToLicense yes -mode silent && \
    rm -rf /opt/mcr_install /tmp/*

RUN mkdir $HOME/work && chmod -R 777 $HOME/work && \
    mkdir $HOME/work/mcrCache && \
    mkdir $HOME/work/mcrCache/.mcrCache9.5

ENV LD_LIBRARY_PATH "/opt/mcr/v95/runtime/glnxa64:/opt/mcr/v94/bin/glnxa64:/opt/mcr/v95/sys/os/glnxa64:/opt/mcr/v95/sys/opengl/lib/glnxa64"
ENV XAPPLERESDIR "/opt/mcr/v95/X11/app-defaults"

ENV MCR_CACHE_ROOT "$HOME/work/mcrCache"

RUN wget https://osf.io/ch3fv/download -O $HOME/work/qMRLab.zip && \
    ls $HOME/work && \
    unzip -q $HOME/work/qMRLab.zip -d $HOME/work

RUN chmod -R 777 $HOME/work
WORKDIR /root/work
ENTRYPOINT ["sh","run_qMRLab.sh","/opt/mcr/v95"]

USER $QMRLAB_USER
