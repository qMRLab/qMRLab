#!/bin/sh

# Assumptions: 
# 1) Local machine has MATLAB installed and added it to the system path
# 2) Local machine has Docker installed 
# 3) Local machine has Azure agent set as described in https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/v2-linux?view=azure-devops
# 4) https://github.com/osfclient/osfclient is installed 
# 5) /tmp folder will be used for intermediary file exhange 

# AZURE DEVOPS --> https://devops.azure.com/qmrlab
# /Pipelines/Releases/Release Pipelines/qMRLab release pipeline
# This script pertains to Compile R2018b (v95) stage 
# $(OSF_USERNAME) $(OSF_PASSWORD) are passed as arguments, to be received as $1 # and $2 by this script. 

# Secret variables are kept in qMRLab/Pipelines/Library/qMRLab Release envs variable group.

# Author: Agah Karakuzu
# ====================================================================

# Get version name from the repo (forked by Azure or another service)

version=`cat $AGENT_RELEASEDIRECTORY/$RELEASE_PRIMARYARTIFACTSOURCEALIAS/version.txt`
echo "Compiling for version: $version"

# Crate tmp directory for compiling 
mkdir -p /tmp/qMRLab
# Remove files from the previous build
rm -rf /tmp/qMRLab/*

# Compile 
# This will do it async, cannot manage flow. 
# mx "disp('$AGENT_RELEASEDIRECTORY'); cd('$AGENT_RELEASEDIRECTORY/$RELEASE_PRIMARYARTIFACTSOURCEALIAS'); startup; qMRLab_make_standalone('/tmp/qMRLab');"

export OSF_PROJECT=tmdfu 
export OSF_USERNAME=$1
export OSF_PASSWORD=$2

matlab -nojvm -nodisplay -nosplash -r "disp('$AGENT_RELEASEDIRECTORY'); cd('$AGENT_RELEASEDIRECTORY/$RELEASE_PRIMARYARTIFACTSOURCEALIAS'); startup; qMRLab_make_standalone('/tmp/qMRLab'); exit;"

if [ -z "$(ls -A /tmp/qMRLab)" ]; then
   echo "Empty, not zipping anything"
else
#   # Zip compiled files \
cd /tmp/qMRLab
zip -r qMRLab_$version.zip .
cp /tmp/qMRLab/qMRLab_$version.zip $AGENT_RELEASEDIRECTORY/qMRLab_$version.zip

# Upload to osf using osfclient (These files will be collected at Standalone/Ubuntu)
# OSF_USERNAME and OSF_PASSWORD variables are set by the release pipeline


osf upload $AGENT_RELEASEDIRECTORY/qMRLab_$version.zip Standalone/Ubuntu/qMRLab_$version.zip

fi








