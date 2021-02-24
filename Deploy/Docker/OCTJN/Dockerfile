# This Dockerfile is intended for creating an image that contains: 
#   - Jupyter
#   - Octave and SOS kernel 
#   - Interactive plotting (e.g. plotly)
#   - osfclient
# 
# Upon successful built, /home/jovyan/work/qMRLab will contain the qMRLab with the version described
#
#   IMPORTANT! 
#   Do not modify this Dockerfile for dependency configuration. 
#   Any changes to the Python and other dependencies should be described in the
#   accompanying apt.txt and requirements.txt configuration files. 
#
# Author: Agah Karakuzu, 2019
# ==========================================================================

FROM jupyter/base-notebook:016833b15ceb

# PASSED ENV VARS: 
#   TAG: Version identified by version.txt 

USER root

ENV DEBIAN_FRONTEND=noninteractive
# Install apt dependencies
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Moscow
COPY apt.txt /tmp/
RUN apt-get update && \
    apt-get -y install tzdata && \
    cat /tmp/apt.txt | xargs sudo apt-get install -y --no-install-recommends &&\
    apt-get clean && \
    apt-get autoremove && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
COPY . /tmp/

# Install pip dependencies 
# Install SOS kernel 
# Pull qMRLab for deployment 

# Following argument is neccesary. Please see build.sh. 
ARG TAG 
COPY requirements.txt /tmp/
RUN echo ${TAG};\
    pip install --upgrade pip; \
    pip install --requirement /tmp/requirements.txt; \
    python -m sos_notebook.install;\    
    cd $HOME/work; \    
    git clone --recurse-submodules -b ${TAG} --single-branch --depth 1 https://github.com/qMRLab/qMRLab.git;\
    chmod -R 777 $HOME/work/qMRLab; \
    octave --eval "cd /home/jovyan/work/qMRLab; \
                      startup; \
                      savepath(); \
                      pkg list;"
COPY . /tmp/

WORKDIR $HOME/work

USER $NB_UID