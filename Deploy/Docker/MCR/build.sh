# Build and push Docker image for compiled qMRLab (R2018b) 
# Docker image: qmrlab/mcrgui 
# This script can be called manually (not by Azure) as well. 
# If called manually, 3 arguments to be passed with the following order:
#   - Path to the qMRLab root 
#   - Docker username 
#   - Docker password 
# IMPORTANT: 
#   The version tag will be read from the version.txt file. 
#   A corresponding qMRLab_version.zip must exist in OSF (/Standalone/Ubuntu)
#   For further details please see Dockerfile accompanying this file. 
# 
# Author: Agah Karakuzu 
# ==========================================================================

if [ -z "${AGENT_RELEASEDIRECTORY}" ]; then

    echo Starting build on lcl computer qMRLab path passed $qMRdir
    qMRdir=$1
    version=`cat $qMRdir/version.txt`
    DOCKER_USERNAME=$2
    DOCKER_PASSWORD=$3

else # User will pass qMRLab path 
    
    echo Starting build on Azure 
    qMRdir=$AGENT_RELEASEDIRECTORY/$RELEASE_PRIMARYARTIFACTSOURCEALIAS
    version=`cat $qMRdir/version.txt`
    DOCKER_USERNAME=$1
    DOCKER_PASSWORD=$2
fi


USERNAME=qmrlab
IMAGE=mcrgui


# Vraiables are available in Azure

DOCKER_USERNAME=$1
DOCKER_PASSWORD=$2



# Build docker image after navigating to the Dockerfile's directory
cd $qMRdir/Deploy/Docker/MCR
docker build -t $USERNAME/$IMAGE:$version -t $USERNAME/$IMAGE:latest --build-arg TAG=$version .

# PUSH
echo $DOCKER_PASSWORD | docker login --username $DOCKER_USERNAME --password-stdin
docker push $USERNAME/$IMAGE:latest
docker push $USERNAME/$IMAGE:$version

