#!/usr/bin/bash -x

# Install packages and nifi-toolkit
sudo apt-get update
sudo apt-get install jq
sudo apt-get install openjdk-11-jdk
sudo apt-get install wget
sudo apt-get install unzip
sudo sh -c "cd /opt; wget https://archive.apache.org/dist/nifi/1.16.3/nifi-toolkit-1.16.3-bin.zip"
sudo sh -c "cd /opt; unzip nifi-toolkit-1.16.3-bin.zip; chmod -R 755 /opt"
nifipath="/opt/nifi-toolkit-1.16.3"
sourcenifi="http://52.208.110.211:8443"
sourceregistry="http://3.252.41.20:18080" # Lab Registry. Later we will assign this value as a github secret variable
# export JAVA_HOME=/usr/lib/jvm/java-1.11.0-openjdk-amd64
export JAVA_HOME="/usr/lib/jvm/java-18-openjdk-amd64"

# VARIABLES
echo ${GITHUB_REF##/}
#branch=$(echo ${GITHUB_REF##/} |  awk -F"/" '{print $3}')
branch=develop
# Charge .properties, it will choose a file but depends of the $env value that change and depends of the current branch. 
# It also assign $targetenv and $targetnifi variables.
case ${branch} in
  feature*)
    env=dev; echo $env
    targetenv=develop; echo $targetenv
    source ./vars/setup_${env}.properties;;
  develop)
    env=qa; echo $env
    targetenv=qa; echo $targetenv
    source ./vars/setup_${env}.properties;;
  qa) 
    env=prod; echo $env
    targetenv=prod; echo $targetenv
    source ./vars/setup_${env}.properties;;
  *) echo "Error getting branch name"; exit 1 ;;
esac
 
# If the variable target_nifi is empty then the script finish, the one that is assigned into the .properties file
if [[ -z ${targetnifi} ]]
  then
    echo "target_nifi variable is not configured"
    exit 1
 fi
 
 # Charge environment variables from vars/setup.json file
num=$(cat ./flow.json | jq length)
if [[ (-z ${num}) || (${num} -eq 0) ]]
  then
    echo "variable num has not value or the json file is not correctly defined"
    exit 1
fi

# If flow.json file only has 1 flow_name and 1 flow_version then it assigns values without a loop
if [[ $num -eq 1 ]]
  then
    flow_name=$(eval cat ./flow.json | jq '.[].flow_name')
    flow_version=$(cat ./flow.json | jq '.[].flow_version')
fi

sourceflowname=$(echo $flow_name | sed 's/\"//g')
sourceflowversion=$(echo $flow_version | sed 's/\"//g')
sourceflowid=$(${nifipath}/bin/cli.sh nifi pg-list -u ${sourcenifi} -ot json | jq '.[] | select(.name=="'"$sourceflowname"'").versionControlInformation.flowId' | sed 's/\"//g')
sourcebucketid=$(${nifipath}/bin/cli.sh nifi pg-list -u ${sourcenifi} -ot json | jq '.[] | select(.name=="'"$sourceflowname"'").versionControlInformation.bucketId'| sed 's/\"//g')
sourceregid=$(${nifipath}/bin/cli.sh nifi pg-list -u ${sourcenifi} -ot json | jq '.[] | select(.name=="'"$sourceflowname"'").versionControlInformation.registryId' | sed 's/\"//g')

# Inport nifi flow into the target nifi instance
${nifipath}/bin/cli.sh nifi pg-list -u ${targetnifi} -ot json | jq '.[].name' | grep -i ${sourceflowname}
res=$?
# If the flow is not created into the target nifi, then we need to create a new flow and later inport the flow 
if [[ $res -ne 0 ]]
  then
    #${nifipath}/bin/cli.sh nifi pg-import -f ${sourceflowid} -b ${sourcebucketid} -fv ${sourceflowversion} --registryClientId ${sourceregid} -u ${targetnifi}
    ${nifipath}/bin/cli.sh nifi pg-import -f ${sourceflowid} -b ${sourcebucketid} -fv ${sourceflowversion} -u ${targetnifi}
  else 
    targetpgid=$(${nifipath}/bin/cli.sh nifi pg-list -ot json -u ${targetnifi} | jq '.[] | select(.name=="'"${sourceflowname}"'").id')
    ${nifipath}/bin/cli.sh nifi pg-change-version -pgid ${targetpgid} -fv ${sourceflowversion} -u ${targetnifi}
    ${nifipath}/bin/cli.sh nifi pg-enable-services -pgid ${targetpgid} -u ${targetnifi}
    ${nifipath}/bin/cli.sh nifi pg-start -pgid ${targetpgid} -u ${targetnifi}
fi
