#!/bin/bash

# NAME: deploy.sh
# Usage: ./deploy.sh <env> <repo-name> <image-name> <cpu-limit> <pass>
# INITIAL CREATION DATE:	March 18, 2020
# lAST MODIFIED DATE:	March 26, 2020
# AUTHOR:   www.integrationpattern.com
# DESCRIPTION:
# 	This script deploys helm chart for specified product in IBM CP4I, the container image is pulled from the internal OCP image registry

if [ -z $1 ] ; then
	echo "Usage: ./deploy.sh <env> <repo-name> <image-name> <cpu-limit> <pass>"
  exit 1
else
  ENV=$1
  #qa or prod
  RELEASENAME=$2
  #dummy-ds-rel-java
	ACEMQCLIENTIMAGETMP=$3
	#Image name without prefix "-amd64"
  CPULIMIT=$4
  #100m
  PASS=$5
  echo ----
  echo "read value"
  echo ----
fi

if [ "$ENV" == "qa" ]; then
ICPFQDN="icp-console.cpi.testcluster.ocp.tine.no"
ISPROD="false"
IMAGEPULLSECRET="deployer-dockercfg-7vxwq"
elif [ "$ENV" == "prod" ]; then
ICPFQDN="icp-console.cpi.cluster.ocp.tine.no"
ISPROD="true"
IMAGEPULLSECRET="deployer-dockercfg-xxxxxx"
else
  echo "---"
  echo "Invalid <env> in ./deploy.sh, quitting!"
  exit 1
  echo "---"
fi

ACEHELMCHART="pipeline/scripts/ace/*.tgz"
#was "https://raw.githubusercontent.com/IBM/charts/master/repo/entitled/ibm-ace-server-icp4i-prod-3.0.0.tgz"
#ibm-ace-server-icp4i-prod-3.0.0.tgz or pipeline/scripts/ace/*.tgz
NAMESPACE="ace"
ACEIMAGETYPE="acemqclient"

#Replace with image created by Jenkins
#Remove the suffix "-amd64" at end of image as IBM helm chart inserts it at the end of the image during helm install.
#ACEMQCLIENTIMAGETMP=$(echo $ACEMQCLIENTIMAGE | sed 's/-amd64//g');
#ACEMQCLIENTIMAGETMP=$RELEASENAME;
#note that the actual image name has as suffix "-amd64": "$RELEASENAME-amd64". This $RELEASENAME comes from repo name of the git which has the integration(s)
ACEMQCLIENTIMAGEURL="image-registry.openshift-image-registry.svc:5000/$NAMESPACE/$ACEMQCLIENTIMAGETMP"
echo "---"
echo "ACE modified baked image url: $ACEMQCLIENTIMAGEURL"
echo "---"
#Copy binaries from OCP cluster (internal network, inaccessible from internet) and run them in present working directory
#wget --no-check-certificate https://helm cloudctl
#version: cloudctl-linux-amd64-v3.2.2-1532
curl -kLo cloudctl https://$ICPFQDN:443/api/cli/cloudctl-linux-amd64
chmod 755 cloudctl

#version: helm-linux-amd64-v2.12.3
curl -kLo helmpkg.tar.gz https://$ICPFQDN:443/api/cli/helm-linux-amd64.tar.gz
tar -xvzf helmpkg.tar.gz
chmod 755 . linux-amd64/helm

./cloudctl login -a https://$ICPFQDN -n $NAMESPACE -u admin -p $PASS
#-skip-ssl-validation

linux-amd64/helm init
#linux-amd64/helm init --client-only
linux-amd64/helm version --tls

#Check if the release already exists
if [ "$(linux-amd64/helm get $RELEASENAME --tls | grep CHART | cut -d ':' -f1)" == "CHART" ]; then
DEPLOYTYPE="upgrade"
else
DEPLOYTYPE="install"
fi

if [ "$DEPLOYTYPE" == "install" ]; then
  echo "---"
  echo "Applying Helm $DEPLOYTYPE Chart for ACE..."
  echo "---"
  linux-amd64/helm $DEPLOYTYPE --namespace $NAMESPACE --name $RELEASENAME $ACEHELMCHART --set imageType=$ACEIMAGETYPE --set productionDeployment=$ISPROD --set image.acemqclient=$ACEMQCLIENTIMAGEURL --set image.pullSecret=$IMAGEPULLSECRET --set persistence.enabled=false --set persistence.useDynamicProvisioning=false --set aceonly.resources.requests.cpu=25m --set aceonly.resources.limits.cpu=$CPULIMIT --set aceonly.replicaCount=1 --set odTracingConfig.enabled=true --set odTracingConfig.odTracingNamespace=integration --set license=accept --debug --tls
#$ACEHELMCHART?raw=true
elif [ "$DEPLOYTYPE" == "upgrade" ]; then
  echo "---"
  echo "Applying Helm $DEPLOYTYPE Chart for ACE..."
  echo "---"
  linux-amd64/helm $DEPLOYTYPE --namespace $NAMESPACE $RELEASENAME $ACEHELMCHART --set imageType=$ACEIMAGETYPE --set productionDeployment=$ISPROD --set image.acemqclient=$ACEMQCLIENTIMAGEURL --set image.pullSecret=$IMAGEPULLSECRET --set persistence.enabled=false --set persistence.useDynamicProvisioning=false --set aceonly.resources.requests.cpu=25m --set aceonly.resources.limits.cpu=$CPULIMIT --set aceonly.replicaCount=1 --set odTracingConfig.enabled=true --set odTracingConfig.odTracingNamespace=integration --set license=accept --debug --tls
fi

echo "Adding route for the ace server pod"
oc expose svc $RELEASENAME-ibm-ace-server-icp4i-prod --port=7800
echo "---"
echo "Finished Script"
echo "---"

