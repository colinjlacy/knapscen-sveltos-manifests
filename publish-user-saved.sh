#!/bin/bash

################################################################################
# publish-user-saved.sh
# 
# Publishes a user-saved CloudEvent to NATS
# 
# Usage:
#   ./publish-user-saved.sh
#
# Environment Variables:
#   NATS_SERVER   - NATS server URL (default: nats://nats.nats.svc.cluster.local:4222)
#   NATS_USER     - NATS username (default: admin)
#   NATS_PASSWORD - NATS password (default: my-password)
#   CUSTOMER_ID   - Customer UUID (default: generated)
################################################################################

set -e

# Configuration
NATS_SERVER="${NATS_SERVER:-nats://127.0.0.1:38811}"
NATS_USER="${NATS_USER:-admin}"
NATS_PASSWORD="${NATS_PASSWORD:-admin}"
NATS_SUBJECT="${NATS_SUBJECT:-user-saved}"

# Generate timestamp for event ID
TIMESTAMP=$(date -u +"%Y%m%d%H%M%S")
TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Generate or use provided customer ID
CUSTOMER_ID="${CUSTOMER_ID:-$(uuidgen | tr '[:upper:]' '[:lower:]')}"

# Generate CloudEvent JSON
CLOUDEVENT_JSON=$(cat << EOF
{
  "specversion": "1.0",
  "type": "disco.knapscen.user.saved",
  "source": "knapscen.disco",
  "subject": "user-saved-0-${CUSTOMER_ID}",
  "id": "evt-user-${TIMESTAMP}",
  "time": "${TIME}",
  "datacontenttype": "application/json",
  "data": {
    "customer_name": "COLIN!!! Solutions",
    "user_name": "John Smith",
    "user_email": "john.smith@techcorp.com",
    "user_role": "customer_account_owner",
    "email_template": "welcome"
  }
}
EOF
)

# Print event details
echo "=================================================="
echo "Publishing User Saved Event"
echo "=================================================="
echo "NATS Server:   ${NATS_SERVER}"
echo "NATS Subject:  ${NATS_SUBJECT}"
echo "Customer ID:   ${CUSTOMER_ID}"
echo "Event ID:      evt-user-${TIMESTAMP}"
echo "Timestamp:     $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
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
  echo "✅ Successfully published user saved event!"
  echo ""
  echo "To monitor the job execution, run:"
  echo "  kubectl get jobs -n knapscen-jobs -w"
  echo ""
  echo "To view job logs, run:"
  echo "  kubectl logs -n knapscen-jobs job/user-saved-0-${CUSTOMER_ID}"
else
  echo "❌ Failed to publish event to NATS"
  exit 1
fi

