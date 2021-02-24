 # If to execute manually, pass qMRLab's root path  as .../qMRLab
# If Azure release, use full path. 
if [[-z "${AGENT_RELEASEDIRECTORY}"]]; then
    qMRdir=$AGENT_RELEASEDIRECTORY/$RELEASE_PRIMARYARTIFACTSOURCEALIAS
    version=`cat $qMRdir/version.txt`
else # Otherwise use relative path. 
    qMRdir=$1
    version=`cat $qMRdir/version.txt`
    echo From terminal $qMRdir
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
git push
git push --tags

# Remove temporary files 
rm -rf /tmp/qMRLabJNB
