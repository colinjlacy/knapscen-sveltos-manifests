#!/bin/bash

################################################################################
# publish-batch-customers.sh
# 
# Publishes 20 customer-registered CloudEvents to NATS
# Creates predictable, unique customer data by iterating through name combinations
# 
# Usage:
#   ./publish-batch-customers.sh
#
# Environment Variables:
#   NATS_SERVER   - NATS server URL (default: nats://127.0.0.1:38811)
#   NATS_USER     - NATS username (default: admin)
#   NATS_PASSWORD - NATS password (default: admin)
#   BATCH_SIZE    - Number of customers to create (default: 20)
################################################################################

set -e

# Configuration
NATS_SERVER="${NATS_SERVER:-nats://127.0.0.1:38897}"
NATS_USER="${NATS_USER:-admin}"
NATS_PASSWORD="${NATS_PASSWORD:-admin}"
NATS_SUBJECT="customer-registered"
BATCH_SIZE="${BATCH_SIZE:-20}"

# Arrays for data generation
COMPANY_TYPES=("Solutions" "Technologies" "Systems" "Enterprises" "Labs" "Ventures" "Dynamics" "Innovations" "Digital" "Cloud" "Data" "AI" "Software" "Services" "Group" "Corp" "Inc" "LLC" "Ltd" "Partners")
COMPANY_ADJECTIVES=("Advanced" "Global" "Smart" "Dynamic" "Innovative" "Digital" "Future" "Next" "Prime" "Elite" "Pro" "Tech" "Data" "Cloud" "AI" "Quantum" "Cyber" "Virtual" "Agile" "Modern")
FIRST_NAMES=("Alex" "Jordan" "Taylor" "Casey" "Morgan" "Riley" "Avery" "Quinn" "Blake" "Cameron" "Drew" "Emery" "Finley" "Hayden" "Jamie" "Kendall" "Logan" "Parker" "Reese" "Sage" "Skyler" "Tyler" "Val" "River" "Phoenix" "Rowan" "Dakota" "Indigo" "Ocean" "Charlie")
LAST_NAMES=("Smith" "Johnson" "Williams" "Brown" "Jones" "Garcia" "Miller" "Davis" "Rodriguez" "Martinez" "Hernandez" "Lopez" "Gonzalez" "Wilson" "Anderson" "Thomas" "Taylor" "Moore" "Jackson" "Martin" "Lee" "Perez" "Thompson" "White" "Harris" "Sanchez" "Clark" "Ramirez" "Lewis" "Robinson")
SUBSCRIPTION_TIERS=("basic" "groovy" "far-out")

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to generate predictable company name
generate_company_name() {
  local index=$1
  local adj_index=$((index % ${#COMPANY_ADJECTIVES[@]}))
  local type_index=$((index % ${#COMPANY_TYPES[@]}))
  
  # Use different offsets to vary combinations
  adj_index=$(((adj_index + (index / ${#COMPANY_ADJECTIVES[@]})) % ${#COMPANY_ADJECTIVES[@]}))
  
  echo "${COMPANY_ADJECTIVES[$adj_index]} ${COMPANY_TYPES[$type_index]}"
}

# Function to generate predictable user with specific role
generate_user() {
  local user_index=$1
  local role=$2
  local first_index=$((user_index % ${#FIRST_NAMES[@]}))
  local last_index=$((user_index % ${#LAST_NAMES[@]}))
  
  # Offset last name to ensure variety
  last_index=$(((last_index + user_index / ${#FIRST_NAMES[@]}) % ${#LAST_NAMES[@]}))
  
  local first_name="${FIRST_NAMES[$first_index]}"
  local last_name="${LAST_NAMES[$last_index]}"
  local company_domain=$(echo "$COMPANY_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g')
  local email="$(echo "${first_name}" | tr '[:upper:]' '[:lower:]').$(echo "${last_name}" | tr '[:upper:]' '[:lower:]')@${company_domain}.com"
  
  echo "      {
        \"name\": \"${first_name} ${last_name}\",
        \"email\": \"${email}\",
        \"role\": \"${role}\"
      }"
}

# Function to publish a single customer
publish_customer() {
  local customer_num=$1
  local timestamp=$(date -u +"%Y%m%d%H%M%S")
  local time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local customer_id=$(uuidgen | tr '[:upper:]' '[:lower:]')
  
  # Generate predictable data for this customer
  COMPANY_NAME=$(generate_company_name $customer_num)
  local tier_index=$((customer_num % ${#SUBSCRIPTION_TIERS[@]}))
  local subscription_tier="${SUBSCRIPTION_TIERS[$tier_index]}"
  
  # Generate 3 users with specific roles, using different indices
  local user_base=$((customer_num * 3))
  local users_json="$(generate_user $user_base "customer_account_owner"),
$(generate_user $((user_base + 1)) "admin_user"),
$(generate_user $((user_base + 2)) "admin_user")"
  
  # Generate CloudEvent JSON
  local cloudevent_json=$(cat << EOF
{
  "specversion": "1.0",
  "type": "disco.knapscen.customer.registered",
  "source": "knapscen.disco",
  "subject": "${customer_id}",
  "id": "evt-customer-${timestamp}-${customer_num}",
  "time": "${time}",
  "datacontenttype": "application/json",
  "data": {
    "name": "${COMPANY_NAME}",
    "subscription_tier": "${subscription_tier}",
    "users": [
${users_json}
    ]
  }
}
EOF
)
  
  # Publish to NATS
  if nats pub "${NATS_SUBJECT}" "${cloudevent_json}" \
    --server="${NATS_SERVER}" \
    --user="${NATS_USER}" \
    --password="${NATS_PASSWORD}" &>/dev/null; then
    
    echo -e "${GREEN}✓${NC} Customer #${customer_num}: ${COMPANY_NAME} (${subscription_tier})"
    return 0
  else
    echo -e "${YELLOW}✗${NC} Customer #${customer_num}: ${COMPANY_NAME} - FAILED"
    return 1
  fi
}

# Main execution
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║     Publishing Batch Customer Registration Events              ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Configuration:"
echo "  NATS Server: ${NATS_SERVER}"
echo "  Batch Size:  ${BATCH_SIZE} customers"
echo "  Subject:     ${NATS_SUBJECT}"
echo ""
echo "Creating ${BATCH_SIZE} unique customers..."
echo "=================================================="

SUCCESS_COUNT=0
FAILED_COUNT=0
START_TIME=$(date +%s)

# Publish each customer
for i in $(seq 1 $BATCH_SIZE); do
  if publish_customer $i; then
    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
  else
    FAILED_COUNT=$((FAILED_COUNT + 1))
  fi
  
  # Small delay to avoid overwhelming NATS
  sleep 0.1
done

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo "=================================================="
echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                      Batch Summary                              ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo -e "  ${GREEN}Successful:${NC} ${SUCCESS_COUNT}/${BATCH_SIZE}"
echo -e "  ${YELLOW}Failed:${NC}     ${FAILED_COUNT}/${BATCH_SIZE}"
echo "  Duration:   ${DURATION}s"
echo ""

if [ $SUCCESS_COUNT -eq $BATCH_SIZE ]; then
  echo -e "${GREEN}✅ All customers registered successfully!${NC}"
else
  echo -e "${YELLOW}⚠️  Some customers failed to register${NC}"
fi

echo ""
echo "To monitor job execution:"
echo "  kubectl get jobs -n default -w"
echo ""
echo "To view all registered customers:"
echo "  kubectl get jobs -n default | grep customer-registered"
echo ""

exit $FAILED_COUNT

