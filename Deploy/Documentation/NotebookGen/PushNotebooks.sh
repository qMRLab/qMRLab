# This one is intended only for Azure. 
# Do not push tokens if not Azure secrets, otherwise 
# going to be exposed!!!!!

if [ -z "${AGENT_RELEASEDIRECTORY}" ]; then

    echo Starting build on lcl computer qMRLab path passed $qMRdir
    qMRdir=$1
    version=`cat $qMRdir/version.txt`
    GITHUB_TOKEN=$2

else # User will pass qMRLab path 
    
    echo Starting build on Azure 
    qMRdir=$AGENT_RELEASEDIRECTORY/$RELEASE_PRIMARYARTIFACTSOURCEALIAS
    version=`cat $qMRdir/version.txt`
    GITHUB_TOKEN=$1
fi

echo "Compiling for version: $version"

nbRoot=/tmp/qMRLabJNB
nbSub=$nbRoot/notebooks

# Crate tmp directory
mkdir -p $nbSub

NOW=$(date +"%m_%d_%Y_%H_%M")
branchName=$version$NOW


matlab -nodisplay -nosplash -r "cd('$qMRdir'); startup; qMRdeployJNB('$nbRoot'); exit;"


# Cherry pick notebooks and move them 
find $nbRoot -name '*.ipynb*' -exec mv {} $nbSub \;

cd $nbSub
git clone https://github.com/qMRLab/doc_notebooks.git

# Move new notebooks to repo
mv -v $nbSub/* $nbSub/doc_notebooks

git add .
git commit -m "For $version on $NOW"
git tag -a "$version" -m "version $version"
if [ -z "${AGENT_RELEASEDIRECTORY}" ]; then
    git push https://$GITHUB_TOKEN@github.com/qMRLab/doc_notebooks.git -f
    git push https://$GITHUB_TOKEN@github.com/qMRLab/doc_notebooks.git --tags
fi
# Remove temporary files 
rm -rf /tmp/qMRLabJNB