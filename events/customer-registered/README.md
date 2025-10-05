# Customer Registered Event

## Overview

This event is triggered when a new customer registers in the system. It processes the complete customer registration including company information and initial user accounts.

## Event Details

- **NATS Subject**: `customer-registered`
- **CloudEvent Type**: `disco.knapscen.customer.registered`
- **CloudEvent Source**: `knapscen.disco`

## Files

- `eventsource.yaml` - Defines the event matching criteria
- `eventtrigger.yaml` - Links the event to the Job template
- `configmap.yaml` - Contains the Kubernetes Job template

## Job Configuration

**Container Image**: `ghcr.io/colinjlacy/knapscen-register-corporate-customer:latest`

**Environment Variables** (from CloudEvent):
- `COMPANY_NAME` - Company name from event data
- `SUBSCRIPTION_TIER` - Subscription level (basic/groovy/far-out)
- `USERS_JSON` - JSON array of users to create
- `EVENT_ID` - CloudEvent ID
- `EVENT_TIME` - CloudEvent timestamp

**Environment Variables** (from Secret `knapscen-config`):
- `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`
- `NATS_SERVER`, `NATS_STREAM`, `NATS_SUBJECT`, `NATS_USER`, `NATS_PASSWORD`

## Deployment

### Deploy this event workflow:

```bash
kubectl apply -f eventsource.yaml
kubectl apply -f configmap.yaml
kubectl apply -f eventtrigger.yaml
```

### Deploy everything at once:

```bash
kubectl apply -f .
```

### Verify deployment:

```bash
kubectl get eventsource customer-registered
kubectl get eventtrigger customer-registered-trigger
kubectl get configmap customer-registered-job
```

## Testing

### Publish a test event:

```bash
# From repository root
./publish-customer-registered.sh
```

### Monitor the Job:

```bash
# Watch for Job creation
kubectl get jobs -n default -w

# View Job logs
kubectl logs -n default job/customer-registered-<customer-id>
```

## CloudEvent Schema

```json
{
  "specversion": "1.0",
  "type": "disco.knapscen.customer.registered",
  "source": "knapscen.disco",
  "subject": "<customer-uuid>",
  "id": "evt-customer-<timestamp>",
  "time": "<ISO8601-timestamp>",
  "datacontenttype": "application/json",
  "data": {
    "name": "Company Name",
    "subscription_tier": "far-out",
    "users": [
      {
        "name": "User Name",
        "email": "user@company.com",
        "role": "customer_account_owner"
      }
    ]
  }
}
```

## Troubleshooting

### Job not created

1. Check EventSource status:
   ```bash
   kubectl describe eventsource customer-registered
   ```

2. Check EventTrigger status:
   ```bash
   kubectl describe eventtrigger customer-registered-trigger
   ```

3. Check Sveltos logs:
   ```bash
   kubectl logs -n projectsveltos -l control-plane=sc-manager | grep customer-registered
   ```

### Job fails

1. Check Job status:
   ```bash
   kubectl describe job customer-registered-<customer-id>
   ```

2. Check Pod logs:
   ```bash
   kubectl logs -n default -l job-name=customer-registered-<customer-id>
   ```

3. Verify Secret exists:
   ```bash
   kubectl get secret knapscen-config -n default
   ```

## Related Documentation

- [QUICKSTART.md](../../QUICKSTART.md)
- [CLOUDEVENTS-SPEC.md](../../CLOUDEVENTS-SPEC.md)
- [SECRETS-GUIDE.md](../../SECRETS-GUIDE.md)

