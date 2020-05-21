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

# Node preparation in AWS
aws cloudformation create-stack --stack-name k8s-tests-$CLUSTER_ID --template-body file://aws-cloudformation/6-nodes-cluster.json --parameters ParameterKey=SSHKey,ParameterValue=aws_demo_sales_new ParameterKey=TestClusterID,ParameterValue=$CLUSTER_ID

# Waiting for CloudFormation to be done
until [ -z echo "$(aws cloudformation list-stack-resources --stack-name=k8s-tests-$CLUSTER_ID | grep 'ResourceStatus' | grep -v 'CREATE_COMPLETE')" ]; do
  echo "$(aws cloudformation list-stack-resources --stack-name=k8s-tests-$CLUSTER_ID | grep 'ResourceStatus' | grep -v 'CREATE_COMPLETE')"
  echo "Automation is running......"
  sleep 5s
done

# Master nodes
MASTER1_IP=$(nslookup c${CLUSTER_ID}m1 | grep Address | awk 'END { print }' | sed s'/Address: //g')
MASTER2_IP=$(nslookup c${CLUSTER_ID}m2 | grep Address | awk 'END { print }' | sed s'/Address: //g')
MASTER3_IP=$(nslookup c${CLUSTER_ID}m3 | grep Address | awk 'END { print }' | sed s'/Address: //g')
# Worker nodes
WORKER1_IP=$(nslookup c${CLUSTER_ID}w1 | grep Address | awk 'END { print }' | sed s'/Address: //g')
WORKER2_IP=$(nslookup c${CLUSTER_ID}w2 | grep Address | awk 'END { print }' | sed s'/Address: //g')
WORKER3_IP=$(nslookup c${CLUSTER_ID}w3 | grep Address | awk 'END { print }' | sed s'/Address: //g')

# Master nodes IP addresses
echo "MASTER1_IP is $MASTER1_IP"
echo "MASTER2_IP is $MASTER2_IP"
echo "MASTER3_IP is $MASTER3_IP"
# Worker nodes IP addresses
echo "WORKER1_IP is $WORKER1_IP"
echo "WORKER2_IP is $WORKER2_IP"
echo "WORKER3_IP is $WORKER3_IP"

cd kubespray

echo ""
echo "===> Creating a new folder for cluster-$CLUSTER_ID"
cp -rpvf inventory/template-1/ inventory/cluster-$CLUSTER_ID/

echo ""
echo "===> Creating the list of nodes for cluster-$CLUSTER_ID"
declare -a NODES=(master1,$MASTER1_IP master2,$MASTER2_IP master3,$MASTER3_IP worker1,$WORKER1_IP worker2,$WORKER2_IP worker3,$WORKER3_IP)
echo "===> List of nodes: ${NODES[@]}"

echo ""
echo "===> Creating an inventory file for cluster-$CLUSTER_ID"
CONFIG_FILE=inventory/cluster-$CLUSTER_ID/hosts.yml python3 contrib/inventory_builder/inventory.py ${NODES[@]}
echo "===> Inventory file:"
cat inventory/cluster-$CLUSTER_ID/hosts.yml

#echo ""
#echo "===> Removing worker-1 as part of the master nodes in the inventory"
#sed '19d' inventory/cluster-$CLUSTER_ID/hosts.yml > inventory/cluster-$CLUSTER_ID/inventory.yml
#rm inventory/cluster-$CLUSTER_ID/hosts.yml

#echo ""
#echo "===> New inventory file:"
#cat inventory/cluster-$CLUSTER_ID/inventory.yml

echo ""
echo "===> Replacing "
sed -i 's/cluster-X/cluster-'${CLUSTER_ID}'/g' inventory/cluster-$CLUSTER_ID/group_vars/k8s-cluster/k8s-cluster.yml
echo "===> Checking result in the file"
cat inventory/cluster-$CLUSTER_ID/group_vars/k8s-cluster/k8s-cluster.yml | grep cluster-

echo ""
echo "===> Installing Kubernetes"
#ansible-playbook -i inventory/cluster-$CLUSTER_ID/hosts.yml --become --become-user=root cluster.yml
