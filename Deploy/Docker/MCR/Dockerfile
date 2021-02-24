# Dockerized qMRLab GUI
#
# This Dockerfile installs MCR v95 (R2018b) and downloads compiled qMRLab (GUI)
# application (from the OSF) for the same MCR version.
#
# Upon successful built, /home/neuropoly will contain the standalone qMRLab with the version described
# in the Tag of the built Docker images. Please see build.sh for details. 
# 
# For usage instructions, please visit qMRLab's DockerHub organization. 
#
# Author: Agah Karakuzu, 2019
# ===========================================================================

FROM ubuntu:20.04

USER root 

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -qq update && apt-get -qq install -y \
    sudo \
    default-jre \
    default-jdk \
    unzip \
    python3-dev \
    python3-pip \
    xserver-xorg \
    wget && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    cd /usr/local/bin && \
    ln -s /usr/bin/python3 python && \
    pip3 install osfclient && \
    rm -rf ~/.cache/pip

ENV LANG en_US.UTF-8

# INSTALL MATLAB COMPILE RUNTIME R208b (v95)
# Moving libexpat.so.1 due to a conflict between MATLAB and python3
# See more here: https://bbs.archlinux.org/viewtopic.php?pid=1112017#p1112017

RUN mkdir /opt/mcr_install && \
    mkdir /opt/mcr && \
    wget -P /opt/mcr_install http://www.mathworks.com/supportfiles/downloads/R2018b/deployment_files/R2018b/installers/glnxa64/MCR_R2018b_glnxa64_installer.zip && \
    unzip -q /opt/mcr_install/MCR_R2018b_glnxa64_installer.zip -d /opt/mcr_install && \
    /opt/mcr_install/install -destinationFolder /opt/mcr -agreeToLicense yes -mode silent && \
    rm -rf /opt/mcr_install /tmp/* && \
    cd /opt/mcr/v95/bin/glnxa64 && \
    mv libexpat.so.1 libexpat.so.1.NOFIND

# Add user neuropoly UID 1000 
# Download compiled image corresponding to the TAG using OSF client
# Unzip qMRLab, remove compressed files and give +x access for executables
# Create home directory and grant 777 access for MCR cache 

ARG TAG

RUN mkdir -p /home/neuropoly && \
    echo "neuropoly:x:1000:1000:Neuropoly,,,:/home/neuropoly:/bin/bash" >> /etc/passwd && \
    echo "neuropoly:x:1000:" >> /etc/group && \
    echo "neuropoly ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/neuropoly && \
    chmod 0440 /etc/sudoers.d/neuropoly && \
    chown neuropoly:neuropoly -R /home/neuropoly && \
    osf -p tmdfu fetch /Standalone/Ubuntu/qMRLab_$TAG.zip /home/neuropoly/qMRLab.zip && \
    cd /home/neuropoly && \
    unzip  qMRLab.zip && \
    ls /home/neuropoly && \
    rm /home/neuropoly/qMRLab.zip && \
    chmod +x /home/neuropoly/run_qMRLab.sh && \
    chmod +x /home/neuropoly/qMRLab && \
    mkdir /home/neuropoly/mcrCache && \
    mkdir /home/neuropoly/mcrCache/.mcrCache9.5 && \
    chmod -R 777 /home/neuropoly

    

# Set $HOME 

ENV HOME /home/neuropoly

# SET LD_LIBRARY_PATH and XAPPLETRESDIR environment variables 

ENV LD_LIBRARY_PATH "/opt/mcr/v95/runtime/glnxa64:/opt/mcr/v95/bin/glnxa64:/opt/mcr/v95/sys/os/glnxa64:/opt/mcr/v95/sys/opengl/lib/glnxa64:/opt/mcr/v95/sys/extern/bin/glnxa64"
ENV XAPPLERESDIR "/opt/mcr/v95/X11/app-defaults"

# SET MCR CACHE ROOT env variable

ENV MCR_CACHE_ROOT "/home/neuropoly/mcrCache" 

# Set WORKDIR to the directory where qMRLab executables are present for ENTRYPOINT call

WORKDIR /home/neuropoly

USER neuropoly

# Start standalone qMRLab with GUI

ENTRYPOINT ["sh","run_qMRLab.sh","/opt/mcr/v95"]
