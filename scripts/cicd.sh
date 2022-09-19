#!/usr/bin/bash -x

# VARIABLES
sourceenv=lab
targetenv=develop
nifipath="/opt/nifi-toolkit-1.16.3"
sourcenifi="http://52.208.110.211:8443"
targetnifi="http://54.220.59.197:8443"
sourceregistry="http://52.49.253.213:18080" # Lab Registry
targetregistry="http://54.171.38.213:18080" # Dev Registry


sudo apt-get update
sudo apt-get install jq
sudo apt-get install openjdk-11-jdk
sudo apt-get install wget
sudo apt-get install unzip
sudo sh -c "cd /opt; wget https://archive.apache.org/dist/nifi/1.16.3/nifi-toolkit-1.16.3-bin.zip"
sudo sh -c "cd /opt; unzip nifi-toolkit-1.16.3-bin.zip; chmod -R 755 /opt"
export JAVA_HOME=/usr/lib/jvm/java-1.11.0-openjdk-amd64
# Get Bucket Id from source (dev bucket)
sourcebucketid=$(${nifipath}/bin/cli.sh registry list-buckets -u ${sourceregistry} -ot json | jq '.[] | select(.name|test("'"${sourceenv}"'")).identifier')
sourceflows=$(${nifipath}/bin/cli.sh registry list-flows -b ${sourcebucketid} -u ${sourceregistry} -ot json | jq '.[].identifier')
# Get pgId using the flowId obteined in the registry
sourceflowid=$(echo $sourceflows | sed 's/\"//g')
for sourceflow in $sourceflowid
do
        sourceflowversion=$(${nifipath}/bin/cli.sh nifi pg-list -u ${sourcenifi} -ot json | jq '.[] | select(.versionControlInformation.flowId=="'"$sourceflow"'").versionControlInformation.version')
        sourceflowname=$(${nifipath}/bin/cli.sh nifi pg-list -u ${sourcenifi} -ot json | jq '.[] | select(.versionControlInformation.flowId=="'"$sourceflow"'").name')

        ###################################
        # Export flows from source registry
        ###################################
        > flow.json

        ${nifipath}/bin/cli.sh registry export-flow-version -f ${sourceflow} -fv ${sourceflowversion} -o flow.json -u ${sourceregistry}

        # Import flow from json file
        # To import a flow we need to create a new flow in the target registry

        # Getting Target bucket Id
        targetbucketid=$(${nifipath}/bin/cli.sh registry list-buckets -u ${targetregistry} -ot json | jq '.[] | select(.name=="'"$targetenv"'").identifier')
        # Creating a new flow at target registry. It will get the new flow id
        newtargetflowid=$(${nifipath}/bin/cli.sh registry create-flow --flowName ${sourceflowname} -b ${targetbucketid} -u ${targetregistry})
        # Import the flow from json file to the target nifi registry
        targetflowversion=$(${nifipath}/bin/cli.sh registry import-flow-version -f ${newtargetflowid} --input flow.json -u ${targetregistry})
        ${nifipath}/bin/cli.sh nifi pg-import -f ${newtargetflowid} -b ${targetbucketid} -fv ${targetflowversion} -u ${targetnifi}

done
