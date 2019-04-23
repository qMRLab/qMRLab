# Read version from root 
version=`cat ../../../version.txt`
USERNAME=qmrlab
IMAGE=mcrgui

# Build docker image
docker build -t $USERNAME/$IMAGE:$version --build-arg TAG=$version .