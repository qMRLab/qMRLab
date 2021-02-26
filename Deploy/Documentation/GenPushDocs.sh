# This one is intended only for Azure. 
# Do not push tokens if not Azure secrets, otherwise 
# going to be exposed!!!!!

if [ -z "${AGENT_RELEASEDIRECTORY}" ]; then

    echo Starting build on lcl computer qMRLab path passed $qMRdir
    qMRdir=$1
    version=`cat $qMRdir/version.txt`
    GITHUB_TOKEN=$2
    GITHUB_MAIL=$3
    GITHUB_NAME=$4

else # User will pass qMRLab path 
    
    echo Starting build on Azure 
    qMRdir=$AGENT_RELEASEDIRECTORY/$RELEASE_PRIMARYARTIFACTSOURCEALIAS
    version=`cat $qMRdir/version.txt`
    GITHUB_TOKEN=$1
    GITHUB_MAIL=$2
    GITHUB_NAME=$3
fi

echo "Generating documentation: $version"

docRoot=/tmp/docGen
docDir=$docRoot/documentation

# Crate tmp directory
mkdir -p $docRoot
cd $docRoot
git clone https://github.com/qMRLab/documentation.git
cd $docDir
NOW=$(date +"%m_%d_%Y_%H_%M")
declare -xp
echo $PATH
# Generate a branch on the documentation repo that has the same 
# qMRLab branch name.
git checkout -b $BUILD_SOURCEBRANCH
# Generate new documentation sources in this new branch
# we also pass $PATH variable so that matlab knows which py to use
matlab -batch "cd('$qMRdir'); startup; GenerateDocumentation('$docDir','$PATH'); exit;"
cd $docDir
git status
git config user.email "$GITHUB_MAIL"
git config user.name "$GITHUB_NAME"
git add .
git commit -m "$BUILD_SOURCEBRANCH commit $BUILD_SOURCEVERSION"
git push https://$GITHUB_TOKEN@github.com/qMRLab/documentation.git $BUILD_SOURCEBRANCH -f
# Remove temporary files 
rm -rf $docRoot