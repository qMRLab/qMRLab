
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

