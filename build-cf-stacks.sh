#!/usr/bin/env bash

## Executables
AWS=/usr/bin/aws

AWS_REGION='ap-southeast-2'

## VARIABLES
SUDO='/usr/bin/sudo'
DOCKER="${SUDO} /usr/bin/docker"

AWS_ACCOUNT_ID=`$AWS sts get-caller-identity --output text --query 'Account'`

if [ -z "$AWS_ACCOUNT_ID" ]; then
    echo "Couldn't Get AWS Account ID. Ensure you have your AWS creds in the OS Env. EXITING...."
    exit
fi

#Environment Definition
EnvironmentName=Production

#VPC Stack PARAMS
VPCStackPath_YML='cf-templates/vpc.yml'
VPCStackName="${EnvironmentName}-VPC"
VpcCIDR='172.20.0.0/23'
PublicSubnet1CIDR='172.20.0.0/25'
PublicSubnet2CIDR='172.20.0.128/25'
PrivateSubnet1CIDR='172.20.1.0/25'
PrivateSubnet2CIDR='172.20.1.128/25'

#Security Group Stack PARAMS
SGStackPath_YML='cf-templates/security-groups.yml'
SGStackName="${EnvironmentName}-Security-Group"

#RDS Stack PARAMS
RDSStackPath_YML='cf-templates/rds.yml'
RDSStackName="${EnvironmentName}-RDS"
MasterUsername='db_admin' # Not a secure method, only used for demonstraion purposes. Passwords need to be stroed in a secure location
MasterUserPassword='J1m0zNFStgpnR2ur' # Not a secure method, only used for demonstraion purposes. Passwords need to be stroed in a secure location
DatabaseName='assemblypayments' # Not a secure method, only used for demonstraion purposes. Passwords need to be stroed in a secure location

#ECR Stack PARAMS
ECRStackPath_YML='cf-templates/ecr.yml'
ECRStackName="${EnvironmentName}-ECR"
RepositoryName='assembly-payments'
#ECR Login
ECR_LOGIN=`$AWS ecr get-login --no-include-email --region $AWS_REGION`

#Load Balancer Stack PARAMS
LBStackPath_YML='cf-templates/loadbalancer.yml'
LBStackName="${EnvironmentName}-LoadBalancer"

#ECS Stack PARAMS
ECSStackPath_YML='cf-templates/ecs.yml'
ECSStackName="${EnvironmentName}-ECS"
InstanceType='t2.micro'
ClusterSize=2
AMIId='ami-bc04d5de'

# ECS Service Stack PARAMS
ECSServiceStackPath_YML='cf-templates/ecs-service.yml'
ECSServiceStackName="${EnvironmentName}-ECSService"
ECSServiceDesiredCont=2
ECSServiceMaxCount=3

##################### START BUILDING ################################

## VPC Build
echo "### Building VPC Stack...."
$AWS cloudformation create-stack --stack-name $VPCStackName --template-body file://$VPCStackPath_YML \
--parameters \
	ParameterKey=EnvironmentName,ParameterValue=$EnvironmentName \
	ParameterKey=VpcCIDR,ParameterValue=$VpcCIDR \
	ParameterKey=PublicSubnet1CIDR,ParameterValue=$PublicSubnet1CIDR \
	ParameterKey=PublicSubnet2CIDR,ParameterValue=$PublicSubnet2CIDR \
	ParameterKey=PrivateSubnet1CIDR,ParameterValue=$PrivateSubnet1CIDR \
	ParameterKey=PrivateSubnet2CIDR,ParameterValue=$PrivateSubnet2CIDR

### Wait for stack to complete
$AWS cloudformation wait stack-create-complete --stack-name $VPCStackName

# ### Check command
# if [ $? -ne 0 ]; then
#     echo "EXITING...."
#     exit
# fi

## Security Group Build
echo "### Building Security Group Stack...."
$AWS cloudformation create-stack --stack-name $SGStackName --template-body file://$SGStackPath_YML \
--parameters \
	ParameterKey=EnvironmentName,ParameterValue=$EnvironmentName \
	ParameterKey=VPCStackName,ParameterValue=$VPCStackName

### Wait for stack to complete
$AWS cloudformation wait stack-create-complete --stack-name $SGStackName
  ### Check command
if [ $? -ne 0 ]; then
    echo "EXITING...."
    exit
fi

  ## RDS Build
  echo "### Building RDS Stack...."
  $AWS cloudformation create-stack --stack-name $RDSStackName --template-body file://$RDSStackPath_YML \
  --parameters \
  	ParameterKey=EnvironmentName,ParameterValue=$EnvironmentName \
  	ParameterKey=VPCStackName,ParameterValue=$VPCStackName \
  	ParameterKey=SecurityGroupStackName,ParameterValue=$SGStackName \
  	ParameterKey=MasterUsername,ParameterValue=$MasterUsername \
  	ParameterKey=MasterUserPassword,ParameterValue=$MasterUserPassword \
  	ParameterKey=DatabaseName,ParameterValue=$DatabaseName

  ### Wait for stack to complete
  $AWS cloudformation wait stack-create-complete --stack-name $RDSStackName
    ### Check command
  if [ $? -ne 0 ]; then
      echo "EXITING...."
      exit
  fi

# GET RDS HOSTNAME
	RDS_HOSTANME=$($AWS cloudformation list-exports --query "Exports[?Name==\`${RDSStackName}-RDSEndPoint\`].Value" --no-paginate --output text)


## ECR Build
echo "### Building ECR Stack...."
$AWS cloudformation create-stack --capabilities CAPABILITY_NAMED_IAM --stack-name $ECRStackName --template-body file://$ECRStackPath_YML \
--parameters \
	ParameterKey=EnvironmentName,ParameterValue=$EnvironmentName \
	ParameterKey=RepositoryName,ParameterValue=$RepositoryName
### Wait for stack to complete
$AWS cloudformation wait stack-create-complete --stack-name $ECRStackName
### Check command
if [ $? -ne 0 ]; then
    echo "EXITING...."
    exit
fi

### Build Image and commit to ECR

$ECR_LOGIN

echo "Build Docker Image..."

$DOCKER build -t $RepositoryName docker/.

# Tag Image
$DOCKER tag $RepositoryName:latest ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/$RepositoryName:latest

echo "Pushing Image to AWS repo..."
# Push Image
$DOCKER push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/$RepositoryName:latest


## LoadBalancer Build
echo "### Building Loadbalancer Stack...."
$AWS cloudformation create-stack --capabilities CAPABILITY_NAMED_IAM --stack-name $LBStackName --template-body file://$LBStackPath_YML \
--parameters \
	ParameterKey=EnvironmentName,ParameterValue=$EnvironmentName \
	ParameterKey=VPCStackName,ParameterValue=$VPCStackName
### Wait for stack to complete
$AWS cloudformation wait stack-create-complete --stack-name $LBStackName
### Check command
if [ $? -ne 0 ]; then
    echo "EXITING...."
    exit
fi

## ECS Build
echo "### Building ECS Stack...."
$AWS cloudformation create-stack --capabilities CAPABILITY_NAMED_IAM --stack-name $ECSStackName --template-body file://$ECSStackPath_YML \
--parameters \
	ParameterKey=EnvironmentName,ParameterValue=$EnvironmentName \
	ParameterKey=InstanceType,ParameterValue=$InstanceType \
	ParameterKey=VPCStackName,ParameterValue=$VPCStackName \
	ParameterKey=SecurityGroupStackName,ParameterValue=$SGStackName \
	ParameterKey=ClusterSize,ParameterValue=$ClusterSize \
	ParameterKey=ImageId,ParameterValue=$AMIId

### Wait for stack to complete
$AWS cloudformation wait stack-create-complete --stack-name $ECSStackName
### Check command
if [ $? -ne 0 ]; then
    echo "EXITING...."
    exit
fi

## ECS Service Build
echo "### Building ECS Service Stack...."
$AWS cloudformation create-stack --capabilities CAPABILITY_NAMED_IAM --stack-name $ECSServiceStackName --template-body file://$ECSServiceStackPath_YML \
--parameters \
	ParameterKey=ECSStackName,ParameterValue=$ECSStackName \
	ParameterKey=VPCStackName,ParameterValue=$VPCStackName \
	ParameterKey=DesiredCount,ParameterValue=$ECSServiceDesiredCont \
	ParameterKey=MaxCount,ParameterValue=$ECSServiceMaxCount \
	ParameterKey=AWSRDSHostname,ParameterValue=$RDS_HOSTANME \
	ParameterKey=AWSRDSUserName,ParameterValue=$MasterUsername \
	ParameterKey=AWSRDSPassword,ParameterValue=$MasterUserPassword \
	ParameterKey=DataBaseName,ParameterValue=$DatabaseName \
	ParameterKey=Path,ParameterValue=/ \
	ParameterKey=Listener,ParameterValue=80 \
	ParameterKey=ECRURL,ParameterValue=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/$RepositoryName \
	ParameterKey=LoadBalancerStackName,ParameterValue=$LBStackName

### Wait for stack to complete
$AWS cloudformation wait stack-create-complete --stack-name $ECSServiceStackName
### Check command
if [ $? -ne 0 ]; then
    echo "EXITING...."
    exit
fi
