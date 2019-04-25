# Read version from root 
version=`cat ../../../version.txt`
USERNAME=qmrlab
IMAGE=octjn

DOCKER_USERNAME=$1
DOCKER_USERNAME=$2

# Vraiables are available in Azure
docker login -u="$DOCKER_USERNAME" -p="$DOCKER_PASSWORD"

# Build docker image
docker build -t $USERNAME/$IMAGE:$version --build-arg TAG=$version .

docker tag $USERNAME/$IMAGE:latest $USERNAME/$IMAGE:$version

# PUSH

docker push $USERNAME/$IMAGE:latest
docker push $USERNAME/$IMAGE:$version


