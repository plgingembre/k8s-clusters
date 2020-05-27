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
read -p "Enter the number of master nodes: " MASTER_NODES

echo ""
echo "===> Results of your variables:"
echo "Cluster ID: $CLUSTER_ID"
echo "Number of Master nodes: $MASTER_NODES"

# Node preparation in AWS
echo ""
echo "===> Creating a CloudFormation stack in AWS named k8s-tests-$CLUSTER_ID"
aws cloudformation create-stack --stack-name k8s-tests-$CLUSTER_ID --template-body file://aws-cloudformation/6-nodes-centos-7-8-v1.json --parameters ParameterKey=SSHKey,ParameterValue=aws_demo_sales_new ParameterKey=TestClusterID,ParameterValue=$CLUSTER_ID

# Waiting for CloudFormation to be done
echo ""
until [ ! -z "$(aws cloudformation describe-stacks --stack-name=k8s-tests-$CLUSTER_ID | grep 'CREATE_COMPLETE')" ]; do
  #echo "$(aws cloudformation describe-stacks --stack-name=k8s-tests-$CLUSTER_ID | grep 'StackStatus')"
  echo "Automation is running......"
  sleep 20s
done

# Master nodes
MASTER1_IP=$(nslookup c${CLUSTER_ID}m1 | grep Address | awk 'END { print }' | sed s'/Address: //g')
MASTER2_IP=$(nslookup c${CLUSTER_ID}m2 | grep Address | awk 'END { print }' | sed s'/Address: //g')
MASTER3_IP=$(nslookup c${CLUSTER_ID}m3 | grep Address | awk 'END { print }' | sed s'/Address: //g')
# Worker nodes
WORKER1_IP=$(nslookup c${CLUSTER_ID}w1 | grep Address | awk 'END { print }' | sed s'/Address: //g')
WORKER2_IP=$(nslookup c${CLUSTER_ID}w2 | grep Address | awk 'END { print }' | sed s'/Address: //g')
WORKER3_IP=$(nslookup c${CLUSTER_ID}w3 | grep Address | awk 'END { print }' | sed s'/Address: //g')

echo ""
echo "List of IP addresses for this cluster:"
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
#declare -a NODES=(master1,$MASTER1_IP master2,$MASTER2_IP master3,$MASTER3_IP worker1,$WORKER1_IP worker2,$WORKER2_IP worker3,$WORKER3_IP)
declare -a NODES=($MASTER1_IP $MASTER2_IP $MASTER3_IP $WORKER1_IP $WORKER2_IP $WORKER3_IP)
echo "===> List of nodes: ${NODES[@]}"

echo ""
echo "===> Creating an inventory file for cluster-$CLUSTER_ID"
# Debug outputs
#KUBE_MASTERS="3"
#echo "Debug - KUBE_MASTERS is $KUBE_MASTERS"
#CONFIG_FILE=inventory/cluster-$CLUSTER_ID/hosts.yml
#echo "Debug - CONFIG_FILE is $CONFIG_FILE"
# Executing script to create the hosts inventory for ansible
#HOST_PREFIX="blah" KUBE_MASTERS_MASTERS="3" CONFIG_FILE=inventory/cluster-$CLUSTER_ID/hosts.yml python3 contrib/inventory_builder/inventory.py ${NODES[@]}
KUBE_MASTERS_MASTERS="$MASTER_NODES" CONFIG_FILE=inventory/cluster-$CLUSTER_ID/hosts.yml python3 contrib/inventory_builder/inventory.py ${NODES[@]}
echo ""
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
echo "===> Replacing cluster-X with cluster-$CLUSTER_ID"
sed -i 's/cluster-X/cluster-'${CLUSTER_ID}'/g' inventory/cluster-$CLUSTER_ID/group_vars/k8s-cluster/k8s-cluster.yml
echo "===> Checking result in the file"
cat inventory/cluster-$CLUSTER_ID/group_vars/k8s-cluster/k8s-cluster.yml | grep cluster-

echo ""
echo "===> Waiting for 2 min to let init scripts run"
sleep 2m

echo ""
echo "===> Installing Kubernetes"
ansible-playbook -i inventory/cluster-$CLUSTER_ID/hosts.yml --become --become-user=root cluster.yml

#echo ""
#echo "===> Exporting kubeconfig"
## Getting KUBECONFIG from Master node 1
#scp ubuntu@c${CLUSTER_ID}m1:~/.kube/config ~/.kube/config-cluster-$CLUSTER_ID
## Setting the KUBECONFIG environment variable
#export KUBECONFIG=~/.kube/config-cluster-$CLUSTER_ID

echo ""
echo "===> Done!"
