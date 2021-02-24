# Build and push Docker image for qMRLab to be used in Octave syntax on Jupyter # Notebooks.
# Docker image: qmrlab/octjn 
# This script can be called manually (not by Azure) as well. 
# If called manually, 3 arguments to be passed with the following order:
#   - Path to the qMRLab root 
#   - Docker username 
#   - Docker password 
#
# IMPORTANT! 
#   The version tag will be read from the version.txt file. 
#   For further details please see Dockerfile accompanying this file. 
#   Any changes to the Python and other dependencies should be described in the
#   accompanying apt.txt and requirements.txt configuration files. 
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

echo $version
USERNAME=qmrlab
IMAGE=octjn

# Build docker image
cd $qMRdir/Deploy/Docker/OCTJN
docker build -t $USERNAME/$IMAGE:$version -t $USERNAME/$IMAGE:latest --build-arg TAG=$version .

# PUSH
echo $DOCKER_PASSWORD | docker login --username $DOCKER_USERNAME --password-stdin
docker push $USERNAME/$IMAGE:latest
docker push $USERNAME/$IMAGE:$version