# Read version from root 
#version=`cat ../../../version.txt`
version=`cat $AGENT_RELEASEDIRECTORY/$RELEASE_PRIMARYARTIFACTSOURCEALIAS/version.txt`
USERNAME=qmrlab
IMAGE=mcrgui


# Vraiables are available in Azure

DOCKER_USERNAME=$1
DOCKER_PASSWORD=$2



# Build docker image after navigating to the Dockerfile's directory
cd $AGENT_RELEASEDIRECTORY/$RELEASE_PRIMARYARTIFACTSOURCEALIAS/Deploy/Docker/MCR
docker build -t $USERNAME/$IMAGE:$version -t $USERNAME/$IMAGE:latest --build-arg TAG=$version .

# PUSH
echo $DOCKER_PASSWORD | docker login -u=$DOCKER_USERNAME --password-stdin docker.io
docker push $USERNAME/$IMAGE:latest
docker push $USERNAME/$IMAGE:$version

