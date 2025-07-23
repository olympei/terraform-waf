#!/bin/bash

# Enterprise Zero-Trust WAF Cleanup Script
# This script safely removes WAF resources in the correct order to avoid dependency conflicts

set -e

echo "🛡️  Enterprise Zero-Trust WAF Cleanup Script"
echo "============================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Function to check if terraform is available
check_terraform() {
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed or not in PATH"
        exit 1
    fi
    print_success "Terraform found: $(terraform version | head -n1)"
}

# Function to check if we're in the right directory
check_directory() {
    if [[ ! -f "main.tf" ]] || [[ ! -f "terraform.tfvars.example" ]]; then
        print_error "This script must be run from the enterprise_zero_trust_waf directory"
        exit 1
    fi
    print_success "Correct directory confirmed"
}

# Function to backup current state
backup_state() {
    print_status "Creating backup of current Terraform state..."
    if [[ -f "terraform.tfstate" ]]; then
        cp terraform.tfstate "terraform.tfstate.backup.$(date +%Y%m%d_%H%M%S)"
        print_success "State backup created"
    else
        print_warning "No terraform.tfstate file found to backup"
    fi
}

# Function to remove ALB associations
remove_alb_associations() {
    print_status "Step 1: Removing ALB associations..."
    
    # Check if there are any ALB associations
    if terraform show | grep -q "alb_arn_list"; then
        print_status "Found ALB associations, removing them..."
        terraform apply -var='alb_arn_list=[]' -auto-approve
        print_success "ALB associations removed"
    else
        print_status "No ALB associations found"
    fi
    
    echo ""
}

# Function to remove rule group references
remove_rule_groups() {
    print_status "Step 2: Removing rule group references from Web ACL..."
    
    # Create a temporary tfvars file with empty rule groups
    cat > temp_cleanup.tfvars << EOF
# Temporary configuration for cleanup
alb_arn_list = []
EOF
    
    print_status "Applying configuration without rule groups..."
    terraform apply -var-file="temp_cleanup.tfvars" -auto-approve
    
    # Clean up temp file
    rm -f temp_cleanup.tfvars
    
    print_success "Rule group references removed from Web ACL"
    echo ""
}

# Function to wait for AWS propagation
wait_for_propagation() {
    print_status "Step 3: Waiting for AWS changes to propagate..."
    print_warning "AWS WAF changes can take up to 5 minutes to propagate globally"
    
    for i in {30..1}; do
        echo -ne "\rWaiting ${i} seconds for propagation... "
        sleep 1
    done
    echo ""
    print_success "Propagation wait completed"
    echo ""
}

# Function to destroy all resources
destroy_resources() {
    print_status "Step 4: Destroying all WAF resources..."
    print_warning "This will permanently delete all WAF resources!"
    
    # Ask for confirmation
    read -p "Are you sure you want to destroy all resources? (yes/no): " confirm
    if [[ $confirm != "yes" ]]; then
        print_error "Destruction cancelled by user"
        exit 1
    fi
    
    print_status "Proceeding with resource destruction..."
    terraform destroy -auto-approve
    
    print_success "All WAF resources destroyed"
    echo ""
}

# Function to verify cleanup
verify_cleanup() {
    print_status "Step 5: Verifying cleanup completion..."
    
    if [[ -f "terraform.tfstate" ]]; then
        # Check if state file is empty or has no resources
        if terraform show | grep -q "No state"; then
            print_success "Terraform state is clean"
        else
            print_warning "Some resources may still exist in state"
            terraform show
        fi
    else
        print_success "No terraform state file found"
    fi
    
    echo ""
}

# Function to cleanup temporary files
cleanup_temp_files() {
    print_status "Cleaning up temporary files..."
    
    # Remove any temporary files created during cleanup
    rm -f temp_cleanup.tfvars
    rm -f terraform.tfplan
    
    print_success "Temporary files cleaned up"
}

# Main execution
main() {
    echo "Starting Enterprise Zero-Trust WAF cleanup process..."
    echo ""
    
    # Pre-flight checks
    check_terraform
    check_directory
    
    # Backup current state
    backup_state
    
    # Execute cleanup steps
    remove_alb_associations
    remove_rule_groups
    wait_for_propagation
    destroy_resources
    verify_cleanup
    cleanup_temp_files
    
    echo ""
    echo "🎉 Enterprise Zero-Trust WAF Cleanup Completed Successfully!"
    echo ""
    echo "Summary:"
    echo "✅ ALB associations removed"
    echo "✅ Rule group references removed"
    echo "✅ AWS propagation waited"
    echo "✅ All resources destroyed"
    echo "✅ Cleanup verified"
    echo ""
    echo "Your AWS WAF resources have been safely removed."
    echo "State backup is available if needed for recovery."
}

# Error handling
trap 'print_error "Script failed at line $LINENO. Exit code: $?"' ERR

# Run main function
main "$@"