#!/bin/bash

# NAME: deploy.sh
# Usage: ./deploy.sh <pwd> <repo-name>
# INITIAL CREATION DATE:	March 18, 2020
# lAST MODIFIED DATE:	March 22, 2020
# AUTHOR:   Abu Davis, www.integrationpattern.com
# DESCRIPTION:
# 	This script deploys helm chart for specified product in IBM CP4I, the container image is pulled from the internal OCP image registry

if [ -z $1 ] ; then
	echo "Usage: ./deploy.sh <pwd> <repo-name>"
  exit 1
else
  PASS=$1
  echo ----
  echo "read value"
  echo ----
fi

RELEASENAME="dummy-ds-rel-java"
#dummy-ds-rel-java
CPULIMIT="100m"
ACEHELMCHART="https://raw.githubusercontent.com/IBM/charts/master/repo/entitled/ibm-ace-server-icp4i-prod-3.0.0.tgz"
ISPROD="false"

IMAGEPULLSECRET="deployer-dockercfg-7vxwq"

NAMESPACE="ace"
#PASS=$(curl -ks https://testengine.tine.no/qa/internet/postenpnrlookup/?postnummer=3001);
#PASS="dummy"
CLOUDCTLHOST="icp-console.cpi.testcluster.ocp.tine.no"
ACEIMAGETYPE="acemqclient"

#Replace with image created by Jenkins
#ACEMQCLIENTIMAGE="ace-app-amd64"
#ace-app-amd64
#helloworld-amd64

#Remove the appended "-amd64" at end of image as IBM helm chart inserts it at the end of the image during helm install.
#ACEMQCLIENTIMAGETMP=$(echo $ACEMQCLIENTIMAGE | sed 's/-amd64//g');
ACEMQCLIENTIMAGETMP=$RELEASENAME;
ACEMQCLIENTIMAGEURL="image-registry.openshift-image-registry.svc:5000/$NAMESPACE/$ACEMQCLIENTIMAGETMP"
echo "---"
echo "ACE modified baked image url: $ACEMQCLIENTIMAGEURL"
echo "---"
#Copy binaries from OCP cluster (internal network, inaccessible from internet) and run them in present working directory
#wget --no-check-certificate https://helm cloudctl
#version: cloudctl-linux-amd64-v3.2.2-1532
curl -kLo cloudctl https://icp-console.cpi.testcluster.ocp.tine.no:443/api/cli/cloudctl-linux-amd64
chmod 755 cloudctl

#version: helm-linux-amd64-v2.12.3
curl -kLo helmpkg.tar.gz https://icp-console.cpi.testcluster.ocp.tine.no:443/api/cli/helm-linux-amd64.tar.gz
tar -xvzf helmpkg.tar.gz
chmod 755 . linux-amd64/helm

./cloudctl login -a https://$CLOUDCTLHOST -n $NAMESPACE -u admin -p $PASS
#-skip-ssl-validation

linux-amd64/helm init
#linux-amd64/helm init --client-only
linux-amd64/helm version --tls
echo "---"
echo "Installing Helm Chart for ACE..."
echo "---"
linux-amd64/helm install --namespace ace --name $RELEASENAME $ACEHELMCHART?raw=true --set imageType=$ACEIMAGETYPE --set productionDeployment=$ISPROD --set image.acemqclient=$ACEMQCLIENTIMAGEURL --set image.pullSecret=$IMAGEPULLSECRET --set persistence.enabled=false --set persistence.useDynamicProvisioning=false --set aceonly.resources.requests.cpu=25m --set aceonly.resources.limits.cpu=$CPULIMIT --set aceonly.replicaCount=1 --set odTracingConfig.enabled=true --set odTracingConfig.odTracingNamespace=integration --set license=accept --debug --tls
echo "Adding route for the ace server pod"
oc expose svc $RELEASENAME-ibm-ace-server-icp4i-prod --port=7800
echo "---"
echo "Finished Script"
echo "---"
