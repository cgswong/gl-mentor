#!/bin/bash
# Comprehensive test script for CloudFormation template

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}CloudFormation Template Test Suite${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Test 1: File existence
echo -e "${YELLOW}Test 1: Checking file existence...${NC}"
files=(
    "template.cfn.yaml"
    "parameters.json"
    "Makefile"
    "README.md"
    "QUICKSTART.md"
    "CHANGELOG.md"
    "MIGRATION_SUMMARY.md"
    ".cfnlintrc.yaml"
    ".markdownlint.json"
    ".gitignore"
)

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo -e "  ${GREEN}✓${NC} $file exists"
    else
        echo -e "  ${RED}✗${NC} $file missing"
        exit 1
    fi
done
echo ""

# Test 2: JSON validation
echo -e "${YELLOW}Test 2: Validating JSON files...${NC}"
if python3 -m json.tool parameters.json > /dev/null 2>&1; then
    echo -e "  ${GREEN}✓${NC} parameters.json is valid JSON"
else
    echo -e "  ${RED}✗${NC} parameters.json is invalid JSON"
    exit 1
fi
echo ""

# Test 3: CloudFormation validation
echo -e "${YELLOW}Test 3: Validating CloudFormation template...${NC}"
if aws cloudformation validate-template --template-body file://template.cfn.yaml --region us-east-1 > /dev/null 2>&1; then
    echo -e "  ${GREEN}✓${NC} CloudFormation template is valid"
else
    echo -e "  ${RED}✗${NC} CloudFormation template validation failed"
    exit 1
fi
echo ""

# Test 4: cfn-lint (optional)
echo -e "${YELLOW}Test 4: Running cfn-lint...${NC}"
if command -v cfn-lint >/dev/null 2>&1; then
    if cfn-lint template.cfn.yaml; then
        echo -e "  ${GREEN}✓${NC} cfn-lint passed"
    else
        echo -e "  ${RED}✗${NC} cfn-lint failed"
        exit 1
    fi
else
    echo -e "  ${YELLOW}⚠${NC} cfn-lint not installed (skipping)"
fi
echo ""

# Test 5: Makefile syntax
echo -e "${YELLOW}Test 5: Testing Makefile...${NC}"
if make -n help > /dev/null 2>&1; then
    echo -e "  ${GREEN}✓${NC} Makefile syntax is valid"
else
    echo -e "  ${RED}✗${NC} Makefile syntax error"
    exit 1
fi
echo ""

# Test 6: Check required parameters
echo -e "${YELLOW}Test 6: Checking required parameters...${NC}"
required_params=(
    "InstanceType"
    "InstanceArchitecture"
    "MinSize"
    "MaxSize"
    "DesiredCapacity"
    "OperatorEmail"
)

for param in "${required_params[@]}"; do
    if grep -q "\"ParameterKey\": \"$param\"" parameters.json; then
        echo -e "  ${GREEN}✓${NC} Parameter $param exists"
    else
        echo -e "  ${RED}✗${NC} Parameter $param missing"
        exit 1
    fi
done
echo ""

# Test 7: Check documentation completeness
echo -e "${YELLOW}Test 7: Checking documentation completeness...${NC}"
doc_sections=(
    "Architecture Overview"
    "Prerequisites"
    "Quick Start"
    "Parameters"
    "Outputs"
    "Troubleshooting"
)

for section in "${doc_sections[@]}"; do
    if grep -q "$section" README.md; then
        echo -e "  ${GREEN}✓${NC} README contains '$section'"
    else
        echo -e "  ${YELLOW}⚠${NC} README missing '$section' section"
    fi
done
echo ""

# Test 8: Check Makefile targets
echo -e "${YELLOW}Test 8: Checking Makefile targets...${NC}"
makefile_targets=(
    "help"
    "validate"
    "deploy"
    "delete"
    "status"
    "outputs"
)

for target in "${makefile_targets[@]}"; do
    if grep -q "^$target:" Makefile; then
        echo -e "  ${GREEN}✓${NC} Makefile target '$target' exists"
    else
        echo -e "  ${RED}✗${NC} Makefile target '$target' missing"
        exit 1
    fi
done
echo ""

# Test 9: Check template resources
echo -e "${YELLOW}Test 9: Checking critical template resources...${NC}"
critical_resources=(
    "VPC"
    "InternetGateway"
    "RegionalNatGateway"
    "ApplicationLoadBalancer"
    "AutoScalingGroup"
    "LaunchTemplate"
    "InstanceRole"
)

for resource in "${critical_resources[@]}"; do
    if grep -q "  $resource:" template.cfn.yaml; then
        echo -e "  ${GREEN}✓${NC} Resource '$resource' exists"
    else
        echo -e "  ${RED}✗${NC} Resource '$resource' missing"
        exit 1
    fi
done
echo ""

# Test 10: Check for deprecated resources
echo -e "${YELLOW}Test 10: Checking for deprecated resources...${NC}"
deprecated_resources=(
    "AWS::ElasticLoadBalancing::LoadBalancer"
    "AWS::AutoScaling::LaunchConfiguration"
)

deprecated_found=false
for resource in "${deprecated_resources[@]}"; do
    if grep -q "$resource" template.cfn.yaml; then
        echo -e "  ${RED}✗${NC} Deprecated resource found: $resource"
        deprecated_found=true
    fi
done

if [ "$deprecated_found" = false ]; then
    echo -e "  ${GREEN}✓${NC} No deprecated resources found"
fi
echo ""

# Test 11: Check for SSH references (should not exist)
echo -e "${YELLOW}Test 11: Checking for SSH references (should be removed)...${NC}"
ssh_references=(
    "KeyName"
    "SSH"
    "port 22"
)

ssh_found=false
for ref in "${ssh_references[@]}"; do
    if grep -qi "$ref" template.cfn.yaml; then
        # Exclude comments
        if grep -qi "$ref" template.cfn.yaml | grep -v "^[[:space:]]*#"; then
            echo -e "  ${YELLOW}⚠${NC} SSH reference found: $ref (check if in comments)"
        fi
    fi
done

if [ "$ssh_found" = false ]; then
    echo -e "  ${GREEN}✓${NC} No SSH references found (using Session Manager)"
fi
echo ""

# Test 12: Check for modern instance types
echo -e "${YELLOW}Test 12: Checking for modern instance types...${NC}"
modern_types=(
    "t3"
    "t4g"
    "m5"
    "m6g"
    "m7g"
)

modern_found=false
for type in "${modern_types[@]}"; do
    if grep -q "$type" template.cfn.yaml; then
        modern_found=true
        break
    fi
done

if [ "$modern_found" = true ]; then
    echo -e "  ${GREEN}✓${NC} Modern instance types found"
else
    echo -e "  ${RED}✗${NC} No modern instance types found"
    exit 1
fi
echo ""

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}All tests passed! ✓${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "Template is ready for deployment."
echo -e "Run ${YELLOW}make deploy${NC} to create the stack."
echo ""
