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
sleep 5s

until [ -z $(aws cloudformation list-stack-resources --stack-name=k8s-tests-$CLUSTER_ID | grep ResourceStatus | grep -v "CREATE_COMPLETE") ]; do
  echo "Automation is running......"
  sleep 5s
  #if [ $(aws ssm get-automation-execution --automation-execution-id "$id" --query 'AutomationExecution.AutomationExecutionStatus' --output text) != "InProgress" ]; then
  #   echo "Automation Finished"
  #   status=$(aws ssm get-automation-execution --automation-execution-id "$id" --query 'AutomationExecution.AutomationExecutionStatus' --output text)
  #   echo "Automation $status"
  #   if [$status != "Success"]; then
  #      exit 3
  #      echo "Automation $status"
  #   fi   
  #  break
  #fi
done

# Master nodes
MASTER1_IP=$(nslookup c$CLUSTER_IPm1 | grep Address | awk 'END { print }' | sed s'/Address: //g')
MASTER2_IP=$(nslookup c$CLUSTER_IPm2 | grep Address | awk 'END { print }' | sed s'/Address: //g')
MASTER3_IP=$(nslookup c$CLUSTER_IPm3 | grep Address | awk 'END { print }' | sed s'/Address: //g')
# Worker nodes
WORKER1_IP=$(nslookup c${CLUSTER_IP}w1 | grep Address | awk 'END { print }' | sed s'/Address: //g')
WORKER2_IP=$(nslookup c${CLUSTER_IP}w2 | grep Address | awk 'END { print }' | sed s'/Address: //g')
WORKER3_IP=$(nslookup c${CLUSTER_IP}w3 | grep Address | awk 'END { print }' | sed s'/Address: //g')

# Master nodes
echo "MASTER1_IP is $MASTER1_IP"
echo "MASTER2_IP is $MASTER2_IP"
echo "MASTER3_IP is $MASTER3_IP"
echo "WORKER1_IP is $WORKER1_IP"
echo "WORKER2_IP is $WORKER2_IP"
echo "WORKER3_IP is $WORKER3_IP"

echo ""
echo "Done!"
