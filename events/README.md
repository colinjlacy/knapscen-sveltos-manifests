# Events Directory

This directory contains all event-driven workflow definitions for the Knapscen customer registration system.

## Directory Structure

Each event type has its own directory containing three files:

```
events/
├── customer-registered/
│   ├── eventsource.yaml      # Event matching criteria
│   ├── configmap.yaml         # Job template
│   ├── eventtrigger.yaml      # Event-to-Job mapping
│   └── README.md              # Event-specific documentation
├── customer-saved/
│   ├── eventsource.yaml
│   ├── configmap.yaml
│   ├── eventtrigger.yaml
│   └── README.md
├── user-saved/
│   ├── ...
├── welcome-email-sent/
│   ├── ...
├── marketing-notified/
│   ├── ...
├── swag-ordered/
│   ├── ...
└── touchpoints-created/
    ├── ...
```

## Event Workflow

1. **customer-registered** - Initial customer registration with users
2. **customer-saved** - Customer data persisted to database
3. **user-saved** - Individual user account created
4. **welcome-email-sent** - Welcome email sent to customer
5. **marketing-notified** - Marketing team notified of new customer
6. **swag-ordered** - Welcome swag package ordered
7. **touchpoints-created** - CRM touchpoints initialized

## Quick Deployment

### Deploy All Events

```bash
# From the events directory
kubectl apply -f customer-registered/
kubectl apply -f customer-saved/
kubectl apply -f user-saved/
kubectl apply -f welcome-email-sent/
kubectl apply -f marketing-notified/
kubectl apply -f swag-ordered/
kubectl apply -f touchpoints-created/
```

### Or use the recursive flag

```bash
kubectl apply -R -f .
```

### Deploy a Single Event

```bash
kubectl apply -f customer-registered/
```

## Deployment Scripts

### Deploy All Events Script

```bash
#!/bin/bash
# deploy-all-events.sh

for event_dir in customer-registered customer-saved user-saved welcome-email-sent marketing-notified swag-ordered touchpoints-created; do
  echo "Deploying $event_dir..."
  kubectl apply -f "$event_dir/"
  echo "✓ $event_dir deployed"
  echo ""
done

echo "All events deployed successfully!"
```

### Deploy Single Event Script

```bash
#!/bin/bash
# deploy-event.sh <event-name>

if [ -z "$1" ]; then
  echo "Usage: ./deploy-event.sh <event-name>"
  echo "Available events:"
  ls -d */ | sed 's#/##'
  exit 1
fi

kubectl apply -f "$1/"
```

## Verification

### Check All EventSources

```bash
kubectl get eventsources
```

Expected output:
```
NAME                    AGE
customer-registered     5m
customer-saved          5m
user-saved              5m
welcome-email-sent      5m
marketing-notified      5m
swag-ordered            5m
touchpoints-created     5m
```

### Check All EventTriggers

```bash
kubectl get eventtriggers
```

### Check All ConfigMaps

```bash
kubectl get configmaps | grep -E "(customer|user|welcome|marketing|swag|touchpoints)"
```

## Event Details

### customer-registered
- **Subject**: `customer-registered`
- **Type**: `disco.knapscen.customer.registered`
- **Purpose**: Process complete customer registration
- **Container**: `ghcr.io/colinjlacy/knapscen-register-corporate-customer:latest`

### customer-saved
- **Subject**: `customer-saved`
- **Type**: `disco.knapscen.customer.saved`
- **Purpose**: Save customer data to database
- **Container**: `knapscen/save-customer:latest`

### user-saved
- **Subject**: `user-saved`
- **Type**: `disco.knapscen.user.saved`
- **Purpose**: Save user account to database
- **Container**: `knapscen/save-user:latest`

### welcome-email-sent
- **Subject**: `welcome-email-sent`
- **Type**: `disco.knapscen.email.welcome.sent`
- **Purpose**: Send welcome email to customer
- **Container**: `knapscen/send-welcome-email:latest`

### marketing-notified
- **Subject**: `marketing-notified`
- **Type**: `disco.knapscen.marketing.notified`
- **Purpose**: Notify marketing team of new customer
- **Container**: `knapscen/notify-marketing:latest`

### swag-ordered
- **Subject**: `swag-ordered`
- **Type**: `disco.knapscen.swag.ordered`
- **Purpose**: Order welcome swag package
- **Container**: `knapscen/order-swag:latest`

### touchpoints-created
- **Subject**: `touchpoints-created`
- **Type**: `disco.knapscen.touchpoints.created`
- **Purpose**: Initialize CRM touchpoints
- **Container**: `knapscen/create-touchpoints:latest`

## Customization

### Modify Container Image

Edit the `configmap.yaml` in the event directory:

```yaml
containers:
- name: my-container
  image: your-registry/your-image:tag
```

### Add Environment Variables

Add to the `env` section in `configmap.yaml`:

```yaml
env:
- name: MY_VARIABLE
  value: "{{ .CloudEvent.data.my_field }}"
```

### Change Cluster Selector

Edit `eventtrigger.yaml`:

```yaml
spec:
  sourceClusterSelector:
    matchLabels:
      environment: production
      role: deploy
```

## Troubleshooting

### No Jobs Created

1. Check EventSource is receiving events:
   ```bash
   kubectl describe eventsource <event-name>
   ```

2. Verify NATS connection:
   ```bash
   kubectl logs -n projectsveltos -l control-plane=sc-manager | grep -i nats
   ```

3. Check cluster labels:
   ```bash
   kubectl get clusters -l role=deploy
   ```

### Jobs Failing

1. Check Job logs:
   ```bash
   kubectl logs -n default job/<job-name>
   ```

2. Verify Secret exists:
   ```bash
   kubectl get secret knapscen-config -n default
   ```

3. Check container image is accessible:
   ```bash
   kubectl get pods -n default -l job-name=<job-name>
   kubectl describe pod <pod-name> -n default
   ```

## Cleanup

### Remove All Events

```bash
kubectl delete -f customer-registered/
kubectl delete -f customer-saved/
kubectl delete -f user-saved/
kubectl delete -f welcome-email-sent/
kubectl delete -f marketing-notified/
kubectl delete -f swag-ordered/
kubectl delete -f touchpoints-created/
```

### Or use recursive delete

```bash
kubectl delete -R -f .
```

### Remove Single Event

```bash
kubectl delete -f customer-registered/
```

## Testing

### Test Customer Registration Flow

```bash
# From repository root
./publish-customer-registered.sh

# Monitor Jobs
kubectl get jobs -n default -w
```

### Test Individual Event

Use NATS CLI to publish a specific event:

```bash
nats pub customer-saved '{
  "specversion": "1.0",
  "type": "disco.knapscen.customer.saved",
  "source": "knapscen.disco",
  "subject": "550e8400-e29b-41d4-a716-446655440000",
  "id": "test-event-001",
  "time": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'",
  "datacontenttype": "application/json",
  "data": {
    "name": "Test Company",
    "subscription_tier": "basic"
  }
}'
```

## See Also

- [Main README](../README.md)
- [QUICKSTART.md](../QUICKSTART.md)
- [DEPLOYMENT-CHECKLIST.md](../DEPLOYMENT-CHECKLIST.md)
- [SECRETS-GUIDE.md](../SECRETS-GUIDE.md)
- [CLOUDEVENTS-SPEC.md](../CLOUDEVENTS-SPEC.md)

