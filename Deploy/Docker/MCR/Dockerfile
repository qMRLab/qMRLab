FROM ubuntu:16.04

USER root 

RUN apt-get -qq update && apt-get -qq install -y \
    sudo \
    default-jre \
    default-jdk \
    unzip \
    xserver-xorg \
    wget && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


RUN mkdir /opt/mcr_install && \
    mkdir /opt/mcr && \
    wget -P /opt/mcr_install http://www.mathworks.com/supportfiles/downloads/R2018b/deployment_files/R2018b/installers/glnxa64/MCR_R2018b_glnxa64_installer.zip && \
    unzip -q /opt/mcr_install/MCR_R2018b_glnxa64_installer.zip -d /opt/mcr_install && \
    /opt/mcr_install/install -destinationFolder /opt/mcr -agreeToLicense yes -mode silent && \
    rm -rf /opt/mcr_install /tmp/*


RUN mkdir -p /home/neuropoly && \
    echo "neuropoly:x:1000:1000:Neuropoly,,,:/home/neuropoly:/bin/bash" >> /etc/passwd && \
    echo "neuropoly:x:1000:" >> /etc/group && \
    echo "neuropoly ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/neuropoly && \
    chmod 0440 /etc/sudoers.d/neuropoly && \
    chown neuropoly:neuropoly -R /home/neuropoly

ENV HOME /home/neuropoly

RUN mkdir /home/neuropoly/mcrCache && \
    mkdir /home/neuropoly/mcrCache/.mcrCache9.5 && \
    chmod -R 777 $HOME

ENV LD_LIBRARY_PATH "/opt/mcr/v95/runtime/glnxa64:/opt/mcr/v95/bin/glnxa64:/opt/mcr/v95/sys/os/glnxa64:/opt/mcr/v95/sys/opengl/lib/glnxa64:/opt/mcr/v95/sys/extern/bin/glnxa64"
ENV XAPPLERESDIR "/opt/mcr/v95/X11/app-defaults"

ENV MCR_CACHE_ROOT "/home/neuropoly/mcrCache"

RUN wget --no-check-certificate https://osf.io/ch3fv/download -O $HOME/qMRLab.zip && \
    ls $HOME && \
    unzip -q $HOME/qMRLab.zip -d $HOME && \
    rm $HOME/qMRLab.zip && \
    chmod +x /home/neuropoly/run_qMRLab.sh && \
    chmod +x /home/neuropoly/qMRLab
    

WORKDIR /home/neuropoly

USER neuropoly
ENTRYPOINT ["sh","run_qMRLab.sh","/opt/mcr/v95"]

USER neuropoly
