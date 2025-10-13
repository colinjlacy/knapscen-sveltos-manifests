#!/bin/bash

################################################################################
# preview-batch-customers.sh
# 
# Previews the 20 customers that will be created by publish-batch-customers.sh
# Does NOT publish to NATS - just shows what will be created
################################################################################

# Arrays for data generation (same as in publish-batch-customers.sh)
COMPANY_TYPES=("Solutions" "Technologies" "Systems" "Enterprises" "Labs" "Ventures" "Dynamics" "Innovations" "Digital" "Cloud" "Data" "AI" "Software" "Services" "Group" "Corp" "Inc" "LLC" "Ltd" "Partners")
COMPANY_ADJECTIVES=("Advanced" "Global" "Smart" "Dynamic" "Innovative" "Digital" "Future" "Next" "Prime" "Elite" "Pro" "Tech" "Data" "Cloud" "AI" "Quantum" "Cyber" "Virtual" "Agile" "Modern")
FIRST_NAMES=("Alex" "Jordan" "Taylor" "Casey" "Morgan" "Riley" "Avery" "Quinn" "Blake" "Cameron" "Drew" "Emery" "Finley" "Hayden" "Jamie" "Kendall" "Logan" "Parker" "Reese" "Sage" "Skyler" "Tyler" "Val" "River" "Phoenix" "Rowan" "Dakota" "Indigo" "Ocean" "Charlie")
LAST_NAMES=("Smith" "Johnson" "Williams" "Brown" "Jones" "Garcia" "Miller" "Davis" "Rodriguez" "Martinez" "Hernandez" "Lopez" "Gonzalez" "Wilson" "Anderson" "Thomas" "Taylor" "Moore" "Jackson" "Martin" "Lee" "Perez" "Thompson" "White" "Harris" "Sanchez" "Clark" "Ramirez" "Lewis" "Robinson")
SUBSCRIPTION_TIERS=("basic" "groovy" "far-out")

BATCH_SIZE=20

# Function to generate predictable company name
generate_company_name() {
  local index=$1
  local adj_index=$((index % ${#COMPANY_ADJECTIVES[@]}))
  local type_index=$((index % ${#COMPANY_TYPES[@]}))
  
  # Use different offsets to vary combinations
  adj_index=$(((adj_index + (index / ${#COMPANY_ADJECTIVES[@]})) % ${#COMPANY_ADJECTIVES[@]}))
  
  echo "${COMPANY_ADJECTIVES[$adj_index]} ${COMPANY_TYPES[$type_index]}"
}

# Function to generate predictable user
generate_user() {
  local user_index=$1
  local role=$2
  local first_index=$((user_index % ${#FIRST_NAMES[@]}))
  local last_index=$((user_index % ${#LAST_NAMES[@]}))
  
  # Offset last name to ensure variety
  last_index=$(((last_index + user_index / ${#FIRST_NAMES[@]}) % ${#LAST_NAMES[@]}))
  
  local first_name="${FIRST_NAMES[$first_index]}"
  local last_name="${LAST_NAMES[$last_index]}"
  
  echo "${first_name} ${last_name} (${role})"
}

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║          Preview: Batch Customer Registration Data             ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "This shows the ${BATCH_SIZE} customers that will be created"
echo ""

# Preview each customer
for i in $(seq 1 $BATCH_SIZE); do
  # Generate predictable data for this customer
  COMPANY_NAME=$(generate_company_name $i)
  tier_index=$((i % ${#SUBSCRIPTION_TIERS[@]}))
  subscription_tier="${SUBSCRIPTION_TIERS[$tier_index]}"
  
  # Generate 3 users with specific roles
  user_base=$((i * 3))
  user1=$(generate_user $user_base "owner")
  user2=$(generate_user $((user_base + 1)) "admin")
  user3=$(generate_user $((user_base + 2)) "admin")
  
  # Calculate company domain
  company_domain=$(echo "$COMPANY_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g')
  
  echo "Customer #${i}:"
  echo "  Company:  ${COMPANY_NAME}"
  echo "  Tier:     ${subscription_tier}"
  echo "  Domain:   ${company_domain}.com"
  echo "  Users:"
  echo "    1. ${user1}"
  echo "    2. ${user2}"
  echo "    3. ${user3}"
  echo ""
done

echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Summary:"
echo "  Total Customers: ${BATCH_SIZE}"
echo "  Total Users:     $((BATCH_SIZE * 3)) (${BATCH_SIZE} owners + $((BATCH_SIZE * 2)) admins)"
echo ""
echo "To publish these customers to NATS:"
echo "  ./publish-batch-customers.sh"
echo ""

