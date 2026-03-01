#!/usr/bin/env bash
# DESC: Create and manage EC2 instances using AWS CLI
# USAGE: ./create_ec2_instance.sh [OPTIONS]

set -euo pipefail
IFS=$'\n\t'

# Configuration
readonly SCRIPT_NAME=$(basename "$0")
readonly PARAM_FILE="${PARAM_FILE:-.ec2-params}"  # Format: KEY=VALUE (one per line, # for comments)
readonly LOG_FILE="${LOG_FILE:-ec2-creation.log}"

# Defaults
AWS_REGION="${AWS_REGION:-us-east-1}"
AWS_PROFILE="${AWS_PROFILE:-default}"
STACK_NAME="${STACK_NAME:-demo-cli}"
IMAGE_ID="${IMAGE_ID:-}"
INSTANCE_TYPE="${INSTANCE_TYPE:-t3.small}"
VPC_ID="${VPC_ID:-}"
SUBNET_ID="${SUBNET_ID:-}"
SECURITY_GROUP_ID="${SECURITY_GROUP_ID:-}"

# Logging functions
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"; }
error() { log "ERROR: $*" >&2; }
die() { error "$*"; exit 1; }

# Display help
show_help() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS]

Create and manage EC2 instances with AWS CLI.

OPTIONS:
    --stack-name NAME          Stack name prefix for resources (default: demo-cli)
    --image-id AMI_ID          AMI ID (defaults to latest Amazon Linux 2023)
    --instance-type TYPE       EC2 instance type (default: t3.small)
    --vpc-id VPC_ID            VPC ID
    --subnet-id SUBNET_ID      Subnet ID
    --security-group-id SG_ID  Security group ID
    --cleanup                  Delete created resources
    --help                     Show this help message

PARAMETER FILE:
    Create $PARAM_FILE with key=value pairs:
        STACK_NAME=my-stack
        IMAGE_ID=ami-xxxxx
        INSTANCE_TYPE=t3.small
        VPC_ID=vpc-xxxxx
        SUBNET_ID=subnet-xxxxx
        SECURITY_GROUP_ID=sg-xxxxx

ENVIRONMENT VARIABLES:
    AWS_REGION, AWS_PROFILE, STACK_NAME, IMAGE_ID, INSTANCE_TYPE, VPC_ID,
    SUBNET_ID, SECURITY_GROUP_ID

EXAMPLES:
    $SCRIPT_NAME --stack-name my-app --subnet-id subnet-123 --security-group-id sg-456
    $SCRIPT_NAME --stack-name my-app --cleanup
EOF
    exit 0
}

# Load parameters from file
load_param_file() {
    [[ -f "$PARAM_FILE" ]] || return 0
    log "Loading parameters from $PARAM_FILE"
    while IFS='=' read -r key value; do
        [[ $key =~ ^[[:space:]]*# ]] && continue
        [[ -z $key ]] && continue
        export "$key=$value"
    done < "$PARAM_FILE"
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --stack-name) STACK_NAME="$2"; shift 2 ;;
            --image-id) IMAGE_ID="$2"; shift 2 ;;
            --instance-type) INSTANCE_TYPE="$2"; shift 2 ;;
            --vpc-id) VPC_ID="$2"; shift 2 ;;
            --subnet-id) SUBNET_ID="$2"; shift 2 ;;
            --security-group-id) SECURITY_GROUP_ID="$2"; shift 2 ;;
            --cleanup) cleanup_resources; exit 0 ;;
            --help|-h) show_help ;;
            *) die "Unknown option: $1. Use --help for usage." ;;
        esac
    done
}

# Get latest Amazon Linux 2023 AMI
get_latest_ami() {
    log "Fetching latest Amazon Linux 2023 AMI ID"
    aws ssm get-parameter \
        --name /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64 \
        --query 'Parameter.Value' \
        --output text \
        --region "$AWS_REGION" \
        --profile "$AWS_PROFILE" || die "Failed to fetch AMI ID"
}

# Validate required parameters
validate_params() {
    [[ -z $STACK_NAME ]] && die "Stack name required"
    [[ -z $SUBNET_ID ]] && die "Subnet ID required"
    [[ -z $SECURITY_GROUP_ID ]] && die "Security group ID required"
    [[ -z $IMAGE_ID ]] && IMAGE_ID=$(get_latest_ami)
    log "Using AMI: $IMAGE_ID"
}

# Create SSH key pair
create_ssh_key() {
    local key_name="${STACK_NAME}-kp"
    local key_file="$HOME/.ssh/${key_name}.pem"

    if [[ -f $key_file ]]; then
        log "SSH key file already exists: $key_file"
        return 0
    fi

    log "Creating SSH key pair: $key_name"
    aws ec2 create-key-pair \
        --key-name "$key_name" \
        --query 'KeyMaterial' \
        --tag-specifications "ResourceType=key-pair,Tags=[{Key=Name,Value=$key_name},{Key=managed-by,Value=aws-cli}]" \
        --output text \
        --region "$AWS_REGION" \
        --profile "$AWS_PROFILE" > "$key_file" || die "Failed to create SSH key"

    chmod 400 "$key_file"
    log "SSH key saved to: $key_file"
}

# Launch EC2 instance
launch_instance() {
    local key_name="${STACK_NAME}-kp"
    local instance_name="${STACK_NAME}-ec2"
    
    log "Launching EC2 instance: $instance_name"
    local instance_id
    instance_id=$(aws ec2 run-instances \
        --image-id "$IMAGE_ID" \
        --count 1 \
        --instance-type "$INSTANCE_TYPE" \
        --key-name "$key_name" \
        --subnet-id "$SUBNET_ID" \
        --security-group-ids "$SECURITY_GROUP_ID" \
        --associate-public-ip-address \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance_name},{Key=managed-by,Value=aws-cli}]" "ResourceType=volume,Tags=[{Key=Name,Value=$instance_name-vol},{Key=managed-by,Value=aws-cli}]" \
        --query 'Instances[0].InstanceId' \
        --output text \
        --region "$AWS_REGION" \
        --profile "$AWS_PROFILE") || die "Failed to launch instance"

    log "Instance created: $instance_id"

    log "Waiting for instance to be running..."
    aws ec2 wait instance-running \
        --instance-ids "$instance_id" \
        --region "$AWS_REGION" \
        --profile "$AWS_PROFILE" || die "Instance failed to start"

    log "Instance is running: $instance_id"
}

# Cleanup resources
cleanup_resources() {
    [[ -z $STACK_NAME ]] && die "Stack name required for cleanup"
    
    log "Starting cleanup for stack: $STACK_NAME"
    local key_name="${STACK_NAME}-kp"
    local instance_name="${STACK_NAME}-ec2"
    
    # Find and terminate instance
    local instance_id
    instance_id=$(aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=$instance_name" "Name=instance-state-name,Values=running,stopped,stopping,pending" \
        --query 'Reservations[0].Instances[0].InstanceId' \
        --output text \
        --region "$AWS_REGION" \
        --profile "$AWS_PROFILE" 2>/dev/null)
    
    if [[ -n $instance_id && $instance_id != "None" ]]; then
        log "Terminating instance: $instance_id"
        aws ec2 terminate-instances \
            --instance-ids "$instance_id" \
            --region "$AWS_REGION" \
            --profile "$AWS_PROFILE" || error "Failed to terminate instance"
    else
        log "No instance found with name: $instance_name"
    fi
    
    # Delete SSH key pair
    log "Deleting SSH key pair: $key_name"
    aws ec2 delete-key-pair \
        --key-name "$key_name" \
        --region "$AWS_REGION" \
        --profile "$AWS_PROFILE" 2>/dev/null || log "Key pair not found: $key_name"
    
    local key_file="$HOME/.ssh/${key_name}.pem"
    [[ -f $key_file ]] && rm -f "$key_file" && log "Deleted key file: $key_file"
    
    log "Cleanup complete"
}

# Main execution
main() {
    unset AWS_CLI_AUTO_PROMPT
    export AWS_PAGER=

    log "Starting $SCRIPT_NAME"

    load_param_file
    parse_args "$@"
    validate_params

    create_ssh_key
    launch_instance

    log "EC2 instance creation complete"
}

main "$@"
