#!/usr/bin/env bash
# DESC: Create or delete AWS VPC infrastructure using AWS CLI
# USAGE: ./create_vpc.sh [OPTIONS]
#        ./create_vpc.sh --stack-name demo --vpc-cidr 10.50.0.0/16 --create-natgw
#        ./create_vpc.sh --cleanup --stack-name demo

set -euo pipefail
IFS=$'\n\t'

# Logging functions
log_info() { echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2; }
log_error() { echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2; }
log_warn() { echo "[WARN] $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2; }

# Default configuration
STACK_NAME="${STACK_NAME:-demo-cli}"
VPC_CIDR="${VPC_CIDR:-10.50.0.0/16}"
SUBNET_CIDRS="${SUBNET_CIDRS:-}"
CREATE_NATGW="${CREATE_NATGW:-false}"
AWS_REGION="${AWS_REGION:-us-east-1}"
CLEANUP=false
PARAM_FILE=""

# AWS CLI configuration
unset AWS_CLI_AUTO_PROMPT
export AWS_PAGER=

show_help() {
    cat << EOF
Usage: ${0##*/} [OPTIONS]

Create or delete AWS VPC infrastructure with public/private subnets.

OPTIONS:
    --stack-name NAME       Prefix for resource naming (default: demo-cli)
    --vpc-cidr CIDR        VPC CIDR block (default: 10.50.0.0/16)
    --subnet-cidrs CIDRS   Comma-separated subnet CIDRs (pub1,pub2,prv1,prv2)
    --create-natgw         Create NAT Gateway (default: false)
    --param-file FILE      Load parameters from file (KEY=VALUE format)
    --cleanup              Delete previously created resources
    --help                 Display this help message

ENVIRONMENT VARIABLES:
    STACK_NAME, VPC_CIDR, SUBNET_CIDRS, CREATE_NATGW, AWS_REGION

EXAMPLES:
    ${0##*/} --stack-name prod --vpc-cidr 10.0.0.0/16 --create-natgw
    ${0##*/} --cleanup --stack-name prod
    STACK_NAME=test ${0##*/} --vpc-cidr 172.16.0.0/16

EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --stack-name) STACK_NAME="$2"; shift 2 ;;
            --vpc-cidr) VPC_CIDR="$2"; shift 2 ;;
            --subnet-cidrs) SUBNET_CIDRS="$2"; shift 2 ;;
            --create-natgw) CREATE_NATGW=true; shift ;;
            --param-file) PARAM_FILE="$2"; shift 2 ;;
            --cleanup) CLEANUP=true; shift ;;
            --help) show_help; exit 0 ;;
            *) log_error "Unknown option: $1"; show_help; exit 1 ;;
        esac
    done
}

load_param_file() {
    [[ -z "$PARAM_FILE" ]] && return
    [[ ! -f "$PARAM_FILE" ]] && { log_error "Parameter file not found: $PARAM_FILE"; exit 1; }
    log_info "Loading parameters from $PARAM_FILE"
    while IFS='=' read -r key value; do
        [[ "$key" =~ ^#.*$ || -z "$key" ]] && continue
        export "$key"="$value"
    done < "$PARAM_FILE"
}

calculate_subnets() {
    local vpc_cidr=$1
    local prefix=$(echo "$vpc_cidr" | cut -d'/' -f2)
    local base_ip=$(echo "$vpc_cidr" | cut -d'/' -f1)
    local third_octet=$(echo "$base_ip" | cut -d'.' -f3)

    echo "${base_ip%.*.*}.$third_octet.0/24,${base_ip%.*.*}.$((third_octet+1)).0/24,${base_ip%.*.*}.$((third_octet+2)).0/24,${base_ip%.*.*}.$((third_octet+3)).0/24"
}

get_azs() {
    aws ec2 describe-availability-zones --region "$AWS_REGION" \
        --query 'AvailabilityZones[0:2].ZoneName' --output text | tr '\t' ' '
}

create_vpc() {
    log_info "Creating VPC with CIDR $VPC_CIDR"
    aws ec2 create-vpc --cidr-block "$VPC_CIDR" --region "$AWS_REGION" \
        --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=${STACK_NAME}-vpc},{Key=managed-by,Value=aws-cli}]" \
        --query 'Vpc.VpcId' --output text
}

create_subnet() {
    local vpc_id=$1 cidr=$2 az=$3 type=$4
    log_info "Creating $type subnet $cidr in $az"
    aws ec2 create-subnet --vpc-id "$vpc_id" --cidr-block "$cidr" \
        --availability-zone "$az" --region "$AWS_REGION" \
        --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=${STACK_NAME}-${type}-${az}},{Key=managed-by,Value=aws-cli}]" \
        --query 'Subnet.SubnetId' --output text
}

create_igw() {
    local vpc_id=$1
    log_info "Creating Internet Gateway"
    local igw_id=$(aws ec2 create-internet-gateway --region "$AWS_REGION" \
        --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=${STACK_NAME}-igw},{Key=managed-by,Value=aws-cli}]" \
        --query 'InternetGateway.InternetGatewayId' --output text)
    aws ec2 attach-internet-gateway --internet-gateway-id "$igw_id" --vpc-id "$vpc_id" --region "$AWS_REGION"
    echo "$igw_id"
}

create_natgw() {
    local vpc_id=$1 subnet1=$2 subnet2=$3 az1=$4 az2=$5
    log_info "Creating a regional NAT Gateway with Elastic IPs"
    local eip_alloc1=$(aws ec2 allocate-address --domain vpc --region "$AWS_REGION" \
        --tag-specifications "ResourceType=elastic-ip,Tags=[{Key=Name,Value=${STACK_NAME}-${az1}-eip},{Key=managed-by,Value=aws-cli}]" \
        --query 'AllocationId' --output text)
    local eip_alloc2=$(aws ec2 allocate-address --domain vpc --region "$AWS_REGION" \
        --tag-specifications "ResourceType=elastic-ip,Tags=[{Key=Name,Value=${STACK_NAME}-${az2}-eip},{Key=managed-by,Value=aws-cli}]" \
        --query 'AllocationId' --output text)
    local natgw_id=$(aws ec2 create-nat-gateway --vpc-id "$vpc_id" \
        --availability-mode regional \
        --availability-zone-addresses "AvailabilityZone=$az1,AllocationIds=$eip_alloc1" \
        --availability-zone-addresses "AvailabilityZone=$az2,AllocationIds=$eip_alloc2" \
        --region "$AWS_REGION" \
        --tag-specifications "ResourceType=natgateway,Tags=[{Key=Name,Value=${STACK_NAME}-natgw},{Key=managed-by,Value=aws-cli}]" \
        --query 'NatGateway.NatGatewayId' --output text)
    log_info "Waiting for regional NAT Gateway to become available..."
    aws ec2 wait nat-gateway-available --nat-gateway-ids "$natgw_id" --region "$AWS_REGION"
    echo "$natgw_id"
}

create_route_table() {
    local vpc_id=$1 type=$2
    log_info "Creating $type route table"
    aws ec2 create-route-table --vpc-id "$vpc_id" --region "$AWS_REGION" \
        --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=${STACK_NAME}-${type}-rt},{Key=managed-by,Value=aws-cli}]" \
        --query 'RouteTable.RouteTableId' --output text
}

create_security_group() {
    local vpc_id=$1
    log_info "Creating security group"
    local sg_id=$(aws ec2 create-security-group --group-name "${STACK_NAME}-sg" \
        --description "Security group for ${STACK_NAME}" --vpc-id "$vpc_id" --region "$AWS_REGION" \
        --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=${STACK_NAME}-sg},{Key=managed-by,Value=aws-cli}]" \
        --query 'GroupId' --output text)

    local my_ip=$(curl -s https://checkip.amazonaws.com)
    aws ec2 authorize-security-group-ingress --group-id "$sg_id" --region "$AWS_REGION" \
        --ip-permissions IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges="[{CidrIp=${my_ip}/32}]" \
            IpProtocol=tcp,FromPort=80,ToPort=80,IpRanges="[{CidrIp=${my_ip}/32}]" 2>/dev/null || true
    echo "$sg_id"
}

cleanup_resources() {
    log_info "Starting cleanup for stack: $STACK_NAME"

    local vpc_id=$(aws ec2 describe-vpcs --region "$AWS_REGION" \
        --filters "Name=tag:Name,Values=${STACK_NAME}-vpc" \
        --query 'Vpcs[0].VpcId' --output text 2>/dev/null)

    [[ "$vpc_id" == "None" || -z "$vpc_id" ]] && { log_warn "VPC not found"; return 0; }

    # Delete NAT Gateways and release EIPs
    local natgw_ids=$(aws ec2 describe-nat-gateways --region "$AWS_REGION" \
        --filter "Name=vpc-id,Values=$vpc_id" --query 'NatGateways[?State!=`deleted`].NatGatewayId' --output text)
    for natgw in $natgw_ids; do
        log_info "Deleting NAT Gateway $natgw"
        aws ec2 delete-nat-gateway --nat-gateway-id "$natgw" --region "$AWS_REGION"
    done
    [[ -n "$natgw_ids" ]] && { log_info "Waiting for NAT Gateway deletion..."; sleep 30; }

    local eip_allocs=$(aws ec2 describe-addresses --region "$AWS_REGION" \
        --filters "Name=tag:Name,Values=${STACK_NAME}-eip" --query 'Addresses[].AllocationId' --output text)
    for eip in $eip_allocs; do
        log_info "Releasing Elastic IP $eip"
        aws ec2 release-address --allocation-id "$eip" --region "$AWS_REGION" 2>/dev/null || true
    done

    # Delete security groups
    local sg_ids=$(aws ec2 describe-security-groups --region "$AWS_REGION" \
        --filters "Name=vpc-id,Values=$vpc_id" "Name=group-name,Values=${STACK_NAME}-sg" \
        --query 'SecurityGroups[].GroupId' --output text)
    for sg in $sg_ids; do
        log_info "Deleting security group $sg"
        aws ec2 delete-security-group --group-id "$sg" --region "$AWS_REGION" 2>/dev/null || true
    done

    # Detach and delete IGW
    local igw_id=$(aws ec2 describe-internet-gateways --region "$AWS_REGION" \
        --filters "Name=attachment.vpc-id,Values=$vpc_id" --query 'InternetGateways[0].InternetGatewayId' --output text)
    if [[ "$igw_id" != "None" && -n "$igw_id" ]]; then
        log_info "Detaching and deleting Internet Gateway $igw_id"
        aws ec2 detach-internet-gateway --internet-gateway-id "$igw_id" --vpc-id "$vpc_id" --region "$AWS_REGION"
        aws ec2 delete-internet-gateway --internet-gateway-id "$igw_id" --region "$AWS_REGION"
    fi

    # Delete subnets
    local subnet_ids=$(aws ec2 describe-subnets --region "$AWS_REGION" \
        --filters "Name=vpc-id,Values=$vpc_id" --query 'Subnets[].SubnetId' --output text)
    for subnet in $subnet_ids; do
        log_info "Deleting subnet $subnet"
        aws ec2 delete-subnet --subnet-id "$subnet" --region "$AWS_REGION"
    done

    # Delete route tables (non-main)
    local rt_ids=$(aws ec2 describe-route-tables --region "$AWS_REGION" \
        --filters "Name=vpc-id,Values=$vpc_id" \
        --query 'RouteTables[?Associations[0].Main!=`true`].RouteTableId' --output text)
    for rt in $rt_ids; do
        log_info "Deleting route table $rt"
        aws ec2 delete-route-table --route-table-id "$rt" --region "$AWS_REGION"
    done

    # Delete VPC
    log_info "Deleting VPC $vpc_id"
    aws ec2 delete-vpc --vpc-id "$vpc_id" --region "$AWS_REGION"

    log_info "Cleanup completed successfully"
}

main() {
    parse_args "$@"
    load_param_file

    if [[ "$CLEANUP" == true ]]; then
        cleanup_resources
        exit 0
    fi

    log_info "Starting VPC creation for stack: $STACK_NAME"

    # Calculate subnet CIDRs if not provided
    if [[ -z "$SUBNET_CIDRS" ]]; then
        SUBNET_CIDRS=$(calculate_subnets "$VPC_CIDR")
        log_info "Auto-calculated subnet CIDRs: $SUBNET_CIDRS"
    fi

    IFS=',' read -r pub1_cidr pub2_cidr prv1_cidr prv2_cidr <<< "$SUBNET_CIDRS"
    IFS=' ' read -r az1 az2 <<< "$(get_azs)"

    # Create VPC
    vpc_id=$(create_vpc)
    log_info "VPC created: $vpc_id"

    # Create subnets
    pub_subnet1=$(create_subnet "$vpc_id" "$pub1_cidr" "$az1" "pub")
    pub_subnet2=$(create_subnet "$vpc_id" "$pub2_cidr" "$az2" "pub")
    prv_subnet1=$(create_subnet "$vpc_id" "$prv1_cidr" "$az1" "prv")
    prv_subnet2=$(create_subnet "$vpc_id" "$prv2_cidr" "$az2" "prv")

    # Create IGW
    igw_id=$(create_igw "$vpc_id")

    # Create NAT Gateway if requested
    natgw_id=""
    if [[ "$CREATE_NATGW" == true ]]; then
        natgw_id=$(create_natgw "$vpc_id" "$pub_subnet1" "$pub_subnet2" "$az1" "$az2")
    fi

    # Create route tables
    pub_rt=$(create_route_table "$vpc_id" "pub")
    prv_rt=$(create_route_table "$vpc_id" "prv")

    # Create routes
    log_info "Creating routes"
    aws ec2 create-route --route-table-id "$pub_rt" --destination-cidr-block 0.0.0.0/0 \
        --gateway-id "$igw_id" --region "$AWS_REGION" >/dev/null

    if [[ -n "$natgw_id" ]]; then
        aws ec2 create-route --route-table-id "$prv_rt" --destination-cidr-block 0.0.0.0/0 \
            --nat-gateway-id "$natgw_id" --region "$AWS_REGION" >/dev/null
    fi

    # Associate route tables
    log_info "Associating route tables with subnets"
    aws ec2 associate-route-table --route-table-id "$pub_rt" --subnet-id "$pub_subnet1" --region "$AWS_REGION" >/dev/null
    aws ec2 associate-route-table --route-table-id "$pub_rt" --subnet-id "$pub_subnet2" --region "$AWS_REGION" >/dev/null
    aws ec2 associate-route-table --route-table-id "$prv_rt" --subnet-id "$prv_subnet1" --region "$AWS_REGION" >/dev/null
    aws ec2 associate-route-table --route-table-id "$prv_rt" --subnet-id "$prv_subnet2" --region "$AWS_REGION" >/dev/null

    # Create security group
    sg_id=$(create_security_group "$vpc_id")

    log_info "VPC infrastructure created successfully"
    log_info "VPC ID: $vpc_id | Public Subnets: $pub_subnet1,$pub_subnet2 | Private Subnets: $prv_subnet1,$prv_subnet2"
}

main "$@"
