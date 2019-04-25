# Read version from root 
#version=`cat ../../../version.txt`
version=`cat $AGENT_RELEASEDIRECTORY/$RELEASE_PRIMARYARTIFACTSOURCEALIAS/version.txt`
echo $version
USERNAME=qmrlab
IMAGE=octjn

DOCKER_USERNAME=$1
DOCKER_USERNAME=$2

# Vraiables are available in Azure


# Build docker image
cd $AGENT_RELEASEDIRECTORY/$RELEASE_PRIMARYARTIFACTSOURCEALIAS/Deploy/Docker/OCTJN
docker build -t $USERNAME/$IMAGE:$version -t $USERNAME/$IMAGE:latest --build-arg TAG=$version .

# PUSH
docker login -u=$DOCKER_USERNAME -p=$DOCKER_PASSWORD docker.io
docker push $USERNAME/$IMAGE:latest
docker push $USERNAME/$IMAGE:$version


