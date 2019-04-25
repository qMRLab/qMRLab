# Read version from root 
#version=`cat ../../../version.txt`
version=`cat $AGENT_RELEASEDIRECTORY/$RELEASE_PRIMARYARTIFACTSOURCEALIAS/version.txt`
USERNAME=qmrlab
IMAGE=mcrgui


# Vraiables are available in Azure

DOCKER_USERNAME=$1
DOCKER_PASSWORD=$2

docker login -u=$DOCKER_USERNAME -p=$DOCKER_PASSWORD

# Build docker image
cd $AGENT_RELEASEDIRECTORY/$RELEASE_PRIMARYARTIFACTSOURCEALIAS/Deploy/Docker/MCR
docker build -t $USERNAME/$IMAGE:$version --build-arg TAG=$version .

docker tag $USERNAME/$IMAGE:latest $USERNAME/$IMAGE:$version

# PUSH

docker push $USERNAME/$IMAGE:latest
docker push $USERNAME/$IMAGE:$version

