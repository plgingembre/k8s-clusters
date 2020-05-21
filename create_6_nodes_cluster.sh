#!/bin/bash

# This script is to create a Kubernetes cluster in AWS. Goals and Methodology:
# 1/ launch the cloudformation template to create machines
# 2/ get the name-to-ip of each node
# 3/ copy the template
# 4/ change all variables in the config files of kubespray
# 5/ 

# Prompt the user to get date and locations 
echo ""
echo "===> Plese provide the cluster information:"
read -p "Enter the cluster ID: " CLUSTER_ID

echo ""
echo "===> Results of your variables:"
echo "Cluster ID: $CLUSTER_ID"

# Declaring variables

# Master nodes
MASTER1_IP=nslookup c$CLUSTER_IPm1 | grep Address | awk 'END { print }' | sed s'/Address: //g'
MASTER2_IP=nslookup c$CLUSTER_IPm2 | grep Address | awk 'END { print }' | sed s'/Address: //g'
MASTER3_IP=nslookup c$CLUSTER_IPm3 | grep Address | awk 'END { print }' | sed s'/Address: //g'
# Worker nodes
WORKER1_IP=nslookup "c${CLUSTER_IP}w1" | grep Address | awk 'END { print }' | sed s'/Address: //g'
WORKER2_IP=nslookup "c${CLUSTER_IP}w2" | grep Address | awk 'END { print }' | sed s'/Address: //g'
WORKER3_IP=nslookup "c${CLUSTER_IP}w3" | grep Address | awk 'END { print }' | sed s'/Address: //g'

# Node preparation in AWS
#aws cloudformation create-stack --stack-name k8s-tests-$CLUSTER_ID --template-body file://k8s-tests-clusters.template --parameters ParameterKey=SSHKey,ParameterValue=aws_demo_sales_new ParameterKey=TestClusterID,ParameterValue=$CLUSTER_ID

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
