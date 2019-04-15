#!/bin/sh

# Assumptions: 
# 1) /usr/local/bin/mx can route asynchronous matlab tasks to an existing session named matlab, running on tmux (tmux ls)
# 2) Local machine has MATLAB installed and added it to the system path
# 3) Local machine has Docker installed 
# 4) Local machine has Azure agent set as described in https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/v2-linux?view=azure-devops
# 5) https://github.com/osfclient/osfclient is installed 
# 6) /tmp folder will be used for intermediary file exhange 

# Get version name from the repo (forked by Azure or another service)

version=`cat $AGENT_RELEASEDIRECTORY/$RELEASE_PRIMARYARTIFACTSOURCEALIAS/version.txt`
echo "Compiling for version: $version"

# Crate tmp directory for compiling 
mkdir -p /tmp/qMRLab

# Compile 
# This will do it async, cannot manage flow. 
# mx "disp('$AGENT_RELEASEDIRECTORY'); cd('$AGENT_RELEASEDIRECTORY/$RELEASE_PRIMARYARTIFACTSOURCEALIAS'); startup; qMRLab_make_standalone('/tmp/qMRLab');"

matlab -nojvm -nodisplay -nosplash -r "disp('$AGENT_RELEASEDIRECTORY'); cd('$AGENT_RELEASEDIRECTORY/$RELEASE_PRIMARYARTIFACTSOURCEALIAS'); startup; qMRLab_make_standalone('/tmp/qMRLab');"

if [ -z "$(ls -A /tmp/qMRLab)" ]; then
   echo "Empty, not zipping anything"
else
   # Zip compiled files 
zip -r qMRLab_$version.zip /tmp/qMRLab

fi



# Upload to osf using osfclient (These files will be collected at Standalone/Ubuntu)
# OSF_USERNAME and OSF_PASSWORD variables are set by the release pipeline

projectID=tmdfu 
echo $OSF_USERNAME 



