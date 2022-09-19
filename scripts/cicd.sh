!#/bin/bash

# VARIABLES
nifipath="/opt/nifi-toolkit-1.16.3"
sourceregistry="http://63.32.117.72:18080" # Lab Registry
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
bucketId=$(/opt/nifi-toolkit-1.16.3/bin/cli.sh registry list-buckets -u http://54.216.211.110:18080 -ot json | jq '.[] | select(.name|test("dev")).identifier')
flows=$(/opt/nifi-toolkit-1.16.3/bin/cli.sh registry list-flows -b ${bucketId} -u http://54.216.211.110:18080 -ot json | jq '.[].identifier')
# Get pgId using the flowId obteined in the registry
flowId=$(echo $flows | sed 's/\"//g')
for flow in $flowId
do
  flowVersion=$(/opt/nifi-toolkit-1.16.3/bin/cli.sh nifi pg-list -u http://52.208.110.211:8443 -ot json | jq '.[] | select(.versionControlInformation.flowId=="'"$flow"'").versionControlInformation.version')
  /opt/nifi-toolkit-1.16.3/bin/cli.sh nifi pg-import -b ${bucketId} -f ${flow} -fv 1 -u http://52.208.110.211:8443
done

# Export flows from source registry
> flow.json
${nifipath}/bin/cli.sh registry export-flow-version -f ${flow} -o flow.json -u ${sourceregistry}

# Import flow from json file
# To import a flow we need to create a new flow in the target registry
newflowid=$(${nifipath}/bin/cli.sh registry create-flow -u ${targetregistry})
targetbucket=$(${nifipath}/bin/cli.sh registry list-buckets -u http://54.171.38.213:18080 -ot json | jq '.[] | select(.name=="'"$env"'").identifier')
${nifipath}/bin/cli.sh registry import-flow-version -f ${flow} --input flow.json -u ${targetregistry}
