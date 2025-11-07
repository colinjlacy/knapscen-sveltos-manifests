#!/bin/bash

################################################################################
# publish-customer-registered.sh
# 
# Publishes a customer-registered CloudEvent to NATS
# 
# Usage:
#   ./publish-customer-registered.sh
#
# Environment Variables:
#   NATS_SERVER   - NATS server URL (default: nats://nats.nats.svc.cluster.local:4222)
#   NATS_USER     - NATS username (default: admin)
#   NATS_PASSWORD - NATS password (default: my-password)
#   CUSTOMER_ID   - Customer UUID (default: generated)
################################################################################

set -e

# Configuration
NATS_SERVER="${NATS_SERVER:-nats://k8s-nats-nats-b888b10971-da9b11825b3d2cee.elb.us-east-2.amazonaws.com:4222}"
NATS_USER="${NATS_USER:-admin}"
NATS_PASSWORD="${NATS_PASSWORD:-admin}"
NATS_SUBJECT="customer-registered"

# Generate timestamp for event ID
TIMESTAMP=$(date -u +"%Y%m%d%H%M%S")
TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Generate or use provided customer ID
CUSTOMER_ID="${CUSTOMER_ID:-$(uuidgen | tr '[:upper:]' '[:lower:]')}"

# Arrays for random data generation
COMPANY_TYPES=("Solutions" "Technologies" "Systems" "Enterprises" "Labs" "Ventures" "Dynamics" "Innovations" "Digital" "Cloud" "Data" "AI" "Software" "Services" "Group" "Corp" "Inc" "LLC" "Ltd")
COMPANY_ADJECTIVES=("Advanced" "Global" "Smart" "Dynamic" "Innovative" "Digital" "Future" "Next" "Prime" "Elite" "Pro" "Tech" "Data" "Cloud" "AI" "Quantum" "Cyber" "Virtual" "Agile" "Modern")
FIRST_NAMES=("Alex" "Jordan" "Taylor" "Casey" "Morgan" "Riley" "Avery" "Quinn" "Blake" "Cameron" "Drew" "Emery" "Finley" "Hayden" "Jamie" "Kendall" "Logan" "Parker" "Reese" "Sage" "Skyler" "Tyler" "Val" "River" "Phoenix" "Rowan" "Sage" "Dakota" "Indigo" "Ocean")
LAST_NAMES=("Smith" "Johnson" "Williams" "Brown" "Jones" "Garcia" "Miller" "Davis" "Rodriguez" "Martinez" "Hernandez" "Lopez" "Gonzalez" "Wilson" "Anderson" "Thomas" "Taylor" "Moore" "Jackson" "Martin" "Lee" "Perez" "Thompson" "White" "Harris" "Sanchez" "Clark" "Ramirez" "Lewis" "Robinson")
SUBSCRIPTION_TIERS=("basic" "groovy" "far-out")

# Function to get random element from array (portable)
get_random_element() {
  local array=("$@")
  local array_length=${#array[@]}
  local random_index=$((RANDOM % array_length))
  echo "${array[$random_index]}"
}

# Function to generate random company name
generate_company_name() {
  local adjective=$(get_random_element "${COMPANY_ADJECTIVES[@]}")
  local type=$(get_random_element "${COMPANY_TYPES[@]}")
  echo "${adjective} ${type}"
}

# Function to generate random user with specific role
generate_user() {
  local first_name=$(get_random_element "${FIRST_NAMES[@]}")
  local last_name=$(get_random_element "${LAST_NAMES[@]}")
  local role="$1"  # Role is passed as parameter
  local company_domain=$(echo "$COMPANY_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g')
  local email="$(echo "${first_name}" | tr '[:upper:]' '[:lower:]').$(echo "${last_name}" | tr '[:upper:]' '[:lower:]')@${company_domain}.com"
  
  echo "      {
        \"name\": \"${first_name} ${last_name}\",
        \"email\": \"${email}\",
        \"role\": \"${role}\"
      }"
}

# Generate random data
COMPANY_NAME=$(generate_company_name)
SUBSCRIPTION_TIER=$(get_random_element "${SUBSCRIPTION_TIERS[@]}")

# Generate exactly 3 users with specific roles
# 1 customer_account_owner + 2 admin_user
USERS_JSON="$(generate_user "customer_account_owner"),
$(generate_user "admin_user"),
$(generate_user "admin_user")"

# Generate CloudEvent JSON
CLOUDEVENT_JSON=$(cat << EOF
{
  "specversion": "1.0",
  "type": "disco.knapscen.customer.registered",
  "source": "knapscen.disco",
  "subject": "${CUSTOMER_ID}",
  "id": "evt-customer-${TIMESTAMP}",
  "time": "${TIME}",
  "datacontenttype": "application/json",
  "data": {
    "name": "${COMPANY_NAME}",
    "subscription_tier": "${SUBSCRIPTION_TIER}",
    "users": [
${USERS_JSON}
    ]
  }
}
EOF
)

# Print event details
echo "=================================================="
echo "Publishing Customer Registration Event"
echo "=================================================="
echo "NATS Server:   ${NATS_SERVER}"
echo "NATS Subject:  ${NATS_SUBJECT}"
echo "Customer ID:   ${CUSTOMER_ID}"
echo "Event ID:      evt-customer-${TIMESTAMP}"
echo "Timestamp:     $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo ""
echo "Generated Data:"
echo "  Company:      ${COMPANY_NAME}"
echo "  Tier:         ${SUBSCRIPTION_TIER}"
echo "  Users:        3 (1 owner + 2 admins)"
echo "=================================================="
echo ""
echo "CloudEvent JSON:"
echo "${CLOUDEVENT_JSON}" | jq '.'
echo ""
echo "=================================================="

# Publish to NATS
echo "Publishing to NATS..."
nats pub "${NATS_SUBJECT}" "${CLOUDEVENT_JSON}" \
  --server="${NATS_SERVER}" \
  --user="${NATS_USER}" \
  --password="${NATS_PASSWORD}"

# Check if publish was successful
if [ $? -eq 0 ]; then
  echo "✅ Successfully published customer registration event for '${COMPANY_NAME}'!"
  echo ""
  echo "To monitor the job execution, run:"
  echo "  kubectl get jobs -n default -w"
  echo ""
  echo "To view job logs, run:"
  echo "  kubectl logs -n default job/customer-registered-${CUSTOMER_ID}"
else
  echo "❌ Failed to publish event to NATS"
  exit 1
fi

