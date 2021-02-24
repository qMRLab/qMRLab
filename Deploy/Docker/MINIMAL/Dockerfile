# This Dockerfile is intended for creating an image that contains: 
# - qMRLab with Octave 
# 
# Upon successful built, /root/work will contain the qMRLab with the version described
#
#   IMPORTANT! 
#   Do not modify this Dockerfile for dependency configuration. 
#   Any changes to the should be described in the
#   accompanying apt.txt configuration file. 
#
# Author: Agah Karakuzu, 2020
# ==========================================================================

FROM neurodebian:focal

# Install apt dependencies 
COPY apt.txt /tmp/
ENV DEBIAN_FRONTEND=noninteractive 
RUN apt-get update && \
    xargs -d '\n' -- apt-get install -y --no-install-recommends < /tmp/apt.txt && \
    apt-get clean && \
    apt-get autoremove && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
COPY . /tmp/

ARG TAG 
RUN echo ${TAG}; \
    mkdir $HOME/work; \
    cd $HOME/work; \    
    git clone --recurse-submodules -b ${TAG} --single-branch --depth 1 https://github.com/qMRLab/qMRLab.git;\
    chmod -R 777 $HOME/work/qMRLab; \
    octave --eval "cd $HOME/work/qMRLab; \
                      startup; \
                      savepath(); \
                      pkg list;"
COPY . /tmp/

WORKDIR $HOME/work