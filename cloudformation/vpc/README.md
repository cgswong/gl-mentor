# VPC CloudFormation Template

A comprehensive CloudFormation template for creating AWS VPC infrastructure with configurable subnets, NAT gateways, and networking components.

## Purpose

This template creates a production-ready VPC with:

- Configurable private subnets (2-3) across availability zones
- Optional public subnets (0-3) with internet gateway
- Flexible NAT gateway configurations (none, single, or per-AZ)
- S3 gateway endpoints for cost optimization
- VPC IPAM support for centralized IP management
- Comprehensive tagging and SSM parameter outputs

## Architecture

```ascii
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                VPC (10.100.0.0/16)                             │
│                                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐                │
│  │   AZ-1 (use1-az1) │  │   AZ-2 (use1-az2) │  │   AZ-3 (use1-az3) │                │
│  │                 │  │                 │  │                 │                │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────┐ │                │
│  │ │Public Subnet│ │  │ │Public Subnet│ │  │ │Public Subnet│ │ (Optional)     │
│  │ │   /24       │ │  │ │   /24       │ │  │ │   /24       │ │                │
│  │ └─────────────┘ │  │ └─────────────┘ │  │ └─────────────┘ │                │
│  │       │         │  │       │         │  │       │         │                │
│  │   ┌───▼───┐     │  │   ┌───▼───┐     │  │   ┌───▼───┐     │                │
│  │   │NAT-GW │     │  │   │NAT-GW │     │  │   │NAT-GW │     │ (SINGLE/ALL)   │
│  │   └───────┘     │  │   └───────┘     │  │   └───────┘     │                │
│  │                 │  │                 │  │                 │                │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────┐ │                │
│  │ │Private      │ │  │ │Private      │ │  │ │Private      │ │                │
│  │ │Subnet /24   │ │  │ │Subnet /24   │ │  │ │Subnet /24   │ │ (Mandatory)    │
│  │ └─────────────┘ │  │ └─────────────┘ │  │ └─────────────┘ │                │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘                │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                        Internet Gateway                                │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                      S3 Gateway Endpoint                               │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                 │
│  Route Tables:                                                                  │
│  • Public RT → Internet Gateway                                                 │
│  • Private RT-1 → NAT Gateway AZ1                                               │
│  • Private RT-2 → NAT Gateway AZ2 (or AZ1 if SINGLE)                           │
│  • Private RT-3 → NAT Gateway AZ3 (or AZ1 if SINGLE)                           │
└─────────────────────────────────────────────────────────────────────────────────┘

Key Components:
• VPC with configurable CIDR (default: 10.100.0.0/16)
• 2-3 Private Subnets (mandatory, distributed across AZs)
• 0-3 Public Subnets (optional, with auto-assign public IP)
• NAT Gateways: NONE, SINGLE (shared), or ALL (per-AZ)
• Internet Gateway (created only with public subnets)
• S3 Gateway Endpoint (attached to all route tables)
• Separate route tables per private subnet for NAT flexibility
```

## Usage

### Quick Start

```bash
# Deploy with defaults (2 private subnets, no public subnets)
make deploy STACK_NAME=my-vpc

# Deploy with public subnets and NAT gateway
make deploy STACK_NAME=prod-vpc
```

### Parameters

| Parameter        | Type               | Default         | Description                               |
| ---------------- | ------------------ | --------------- | ----------------------------------------- |
| `VpcCidrs`       | CommaDelimitedList | `10.100.0.0/16` | VPC CIDR blocks (primary + secondary)     |
| `IpamPoolId`     | String             | `""`            | Optional IPAM pool ID for CIDR allocation |
| `PrivateSubnets` | Number             | `2`             | Number of private subnets (2-3)           |
| `PublicSubnets`  | Number             | `0`             | Number of public subnets (0-3)            |
| `NatGateways`    | String             | `NONE`          | NAT configuration: NONE/SINGLE/ALL        |

### Configuration Examples

**Private-only VPC:**

```json
{
  "ParameterKey": "PrivateSubnets", "ParameterValue": "2"
  "ParameterKey": "PublicSubnets", "ParameterValue": "0"
  "ParameterKey": "NatGateways", "ParameterValue": "NONE"
}
```

**Public-private with single NAT:**

```json
{
  "ParameterKey": "PrivateSubnets", "ParameterValue": "3"
  "ParameterKey": "PublicSubnets", "ParameterValue": "3"
  "ParameterKey": "NatGateways", "ParameterValue": "SINGLE"
}
```

**High availability with per-AZ NAT:**

```json
{
  "ParameterKey": "PrivateSubnets", "ParameterValue": "3"
  "ParameterKey": "PublicSubnets", "ParameterValue": "3"
  "ParameterKey": "NatGateways", "ParameterValue": "ALL"
}
```

## Testing

### Validation

```bash
make validate    # Syntax validation
make test       # Full validation with parameter checks
```

### Deployment Testing

```bash
# Test in development environment
make deploy STACK_NAME=test-vpc REGION=us-west-2

# Verify outputs
make status STACK_NAME=test-vpc

# Cleanup
make delete STACK_NAME=test-vpc
```

### Integration Testing

- Deploy with minimal configuration (2 private subnets)
- Deploy with maximum configuration (3 public + 3 private + ALL NAT)
- Test IPAM integration if available
- Verify cross-stack references work with exported outputs

## Outputs

### CloudFormation Exports

- `${StackName}-VpcId`: VPC resource ID
- `${StackName}-VpcCidr`: VPC CIDR block
- `${StackName}-PrivateSubnets`: Comma-separated private subnet IDs
- `${StackName}-PublicSubnets`: Comma-separated public subnet IDs
- `${StackName}-DefaultSecurityGroupId`: Default security group ID

### SSM Parameters

- `/${StackName}/vpc/id`: VPC ID
- `/${StackName}/vpc/cidr`: VPC CIDR
- `/${StackName}/subnets/private`: Private subnet list
- `/${StackName}/subnets/public`: Public subnet list

## Limitations

### Current Limitations

- Maximum 3 subnets per type (private/public)
- Requires minimum 2 private subnets
- Single route table per private subnet (for per-AZ NAT support)
- No IPv6 support
- No VPC peering or transit gateway integration

### Regional Constraints

- Requires regions with at least 2 availability zones
- Third subnet only created if 3+ AZs available
- AZ-ID naming depends on regional AZ availability

### Cost Considerations

- NAT gateways incur hourly charges and data processing fees
- Multiple NAT gateways (ALL option) significantly increase costs
- Consider SINGLE NAT for development environments

## Known Issues

1. **AZ Availability**: Template assumes AZ availability but doesn't validate AZ count before deployment
2. **IPAM Dependencies**: IPAM pool must exist before deployment when using IpamPoolId
3. **Route Table Complexity**: Private route tables use numbered naming instead of AZ-based naming
4. **Condition Logic**: Complex conditions may cause deployment issues in edge cases

## Improvement Opportunities

### Short Term

- Add IPv6 support for dual-stack networking
- Implement VPC Flow Logs configuration
- Add Network ACL customization options
- Include VPC endpoint configurations for other AWS services

### Medium Term

- Add support for more than 3 subnets per type
- Implement custom route table configurations
- Add VPC peering and transit gateway support
- Include DNS resolver configurations

### Long Term

- Multi-region VPC template variant
- Integration with AWS Control Tower
- Advanced networking features (carrier gateway, local zones)
- Automated cost optimization recommendations

## Contributing

1. Validate changes: `make validate`
2. Test thoroughly: `make test`
3. Update documentation for parameter changes
4. Test in multiple regions and AZ configurations
5. Verify backward compatibility

## License

This template is provided as-is for educational and operational use.
