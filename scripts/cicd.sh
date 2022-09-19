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
flows=$(/opt/nifi-toolkit-1.16.3/bin/cli.sh registry list-flows -b ${bucketid} -u http://54.216.211.110:18080 -ot json | jq '.[].identifier')
# Get pgId using the flowId obteined in the registry
flowId=$(echo $flows | sed 's/\"//g')
for flow in $flowId
do
  flowVersion=$(/opt/nifi-toolkit-1.16.3/bin/cli.sh nifi pg-list -u http://52.208.110.211:8443 -ot json | jq '.[] | select(.versionControlInformation.flowId=="'"$flow"'").versionControlInformation.version')
  /opt/nifi-toolkit-1.16.3/bin/cli.sh nifi pg-import -b ${bucketId} -f ${flow} -fv ${flowVersion} --registryClientId 4c2b988e-0183-1000-08cc-7bbc53445064 -u http://52.208.110.211:8443
done
