#!/bin/bash

# This script is to create a Kubernetes cluster in AWS. Goals and Methodology:
# 1/ launch the cloudformation template to create machines
# 2/ get the name-to-ip of each node
# 3/ copy the template
# 4/ change all variables in the config files of kubespray

# Prompt the user to get date and locations 
echo ""
echo "===> Plese provide the cluster information:"
read -p "Enter the cluster ID: " CLUSTER_ID

echo ""
echo "===> Results of your variables:"
echo "Cluster ID: $CLUSTER_ID"

echo ""
echo "===> Deleting CloudFormation stack in AWS"
aws cloudformation delete-stack --stack-name k8s-tests-$CLUSTER_ID

cd ~/kubespray

echo ""
echo "===> Deleting cluster-$CLUSTER_ID folder"
rm -Rf inventory/cluster-$CLUSTER_ID/
