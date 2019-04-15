FROM jupyter/base-notebook:8ccdfc1da8d5

# PASSED ENV VARS: 
#   TAG: Version identified by version.txt 

USER root

# Install apt dependencies 
COPY apt.txt /tmp/
RUN apt-get update && \
    cat /tmp/apt.txt | xargs sudo apt-get install -y --no-install-recommends &&\
    apt-get clean && \
    apt-get autoremove && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
COPY . /tmp/

# Install pip dependencies 
# Install SOS kernel 
# Pull qMRLab for deployment 

ARG TAG 

COPY requirements.txt /tmp/
RUN echo ${TAG};\
    pip install --upgrade pip; \
    pip install --requirement /tmp/requirements.txt; \
    python -m sos_notebook.install;\    
    cd $HOME/work; \    
    git clone -b ${TAG} --single-branch --depth 1 https://github.com/qMRLab/qMRLab.git;\
    chmod -R 777 $HOME/work/qMRLab; \
    octave --eval "cd /home/jovyan/work/qMRLab; \
                      startup; \
                      savepath(); \
                      pkg list;"
COPY . /tmp/

WORKDIR $HOME/work

USER $NB_UID