# Knapscen Sveltos Event-Driven Workflows

This repository contains Sveltos manifests for event-driven customer registration workflows using NATS and CloudEvents.

## 📚 Documentation

- **[Quick Start Guide](QUICKSTART.md)** - Get up and running in 5 minutes
- **[Architecture Overview](ARCHITECTURE.md)** - System design and component details
- **[Event Workflow](WORKFLOW.md)** - Complete event flow documentation
- **[CloudEvents Specification](CLOUDEVENTS-SPEC.md)** - Detailed event schema reference
- **[Database Schema](database_schema.sql)** - MySQL database structure

## Overview

This system implements an event-driven architecture for customer onboarding that:
1. Receives customer registration events via NATS
2. Processes the data through multiple stages
3. Triggers Kubernetes Jobs for each workflow step

## Architecture

### Event Flow

```
Customer Registration (NATS: customer-saved)
    ↓
    ├─> Save Customer to DB (Job)
    ├─> Save Users to DB (NATS: user-saved → Job)
    ├─> Send Welcome Email (NATS: welcome-email-sent → Job)
    ├─> Notify Marketing (NATS: marketing-notified → Job)
    ├─> Order Swag (NATS: swag-ordered → Job)
    └─> Create Touchpoints (NATS: touchpoints-created → Job)
```

### NATS Subjects

The system listens to the following NATS subjects:
- `customer-saved` - Customer data persisted
- `user-saved` - User data persisted
- `welcome-email-sent` - Welcome email sent
- `marketing-notified` - Marketing team notified
- `swag-ordered` - Swag order placed
- `touchpoints-created` - CRM touchpoints created

## Directory Structure

```
.
├── events/                       # Event-driven workflow definitions
│   ├── customer-registered/      # Customer registration event
│   │   ├── eventsource.yaml
│   │   ├── configmap.yaml
│   │   ├── eventtrigger.yaml
│   │   └── README.md
│   ├── customer-saved/           # Customer saved event
│   ├── user-saved/               # User saved event
│   ├── welcome-email-sent/       # Welcome email event
│   ├── marketing-notified/       # Marketing notification event
│   ├── swag-ordered/             # Swag order event
│   └── touchpoints-created/      # Touchpoints creation event
├── sample-cloudevents/           # Sample CloudEvent JSON for reference
├── deploy-all-events.sh          # Deploy all events at once
├── deploy-event.sh               # Deploy a single event
└── database_schema.sql           # Database schema reference
```

## CloudEvent Specification

All events follow the CloudEvents 1.0 specification with:
- **Source**: `knapscen.disco`
- **Subject**: Customer UUID (e.g., `550e8400-e29b-41d4-a716-446655440000`)
- **Type**: Event-specific (e.g., `disco.knapscen.customer.saved`)
- **Data**: JSON payload with event-specific fields

See `sample-cloudevents/` directory for complete examples.

## Deployment

### Prerequisites

1. ProjectSveltos installed in management cluster
2. NATS server deployed and accessible
3. Sveltos connected to NATS (via `sveltos-nats` Secret in `projectsveltos` namespace)
4. Managed clusters labeled with `role=deploy`
5. Namespace `knapscen-jobs` exists in target clusters

### Apply Manifests

```bash
# Deploy all events at once
./deploy-all-events.sh

# Or deploy a specific event
./deploy-event.sh customer-registered

# Or deploy manually
kubectl apply -f events/customer-registered/
```

## Container Images

The following container images must be available:
- `knapscen/save-customer:latest`
- `knapscen/save-user:latest`
- `knapscen/send-welcome-email:latest`
- `knapscen/notify-marketing:latest`
- `knapscen/order-swag:latest`
- `knapscen/create-touchpoints:latest`

## Testing

### Publish Test Events to NATS

```bash
# Install NATS CLI
go install github.com/nats-io/natscli/nats@latest

# Publish a customer-saved event
nats pub customer-saved "$(cat sample-cloudevents/customer-saved.json)" \
  --server=nats://nats.nats.svc.cluster.local:4222 \
  --user=admin --password=my-password

# Publish a user-saved event
nats pub user-saved "$(cat sample-cloudevents/user-saved.json)" \
  --server=nats://nats.nats.svc.cluster.local:4222 \
  --user=admin --password=my-password
```

### Monitor Jobs

```bash
# Watch jobs in target cluster
kubectl get jobs -n knapscen-jobs -w

# Check job logs
kubectl logs -n knapscen-jobs job/customer-saved-550e8400-e29b-41d4-a716-446655440000

# View Sveltos status
sveltosctl show addons
```

## Database Schema

The customer management system uses the following tables:
- `corporate_customers` - Company information and subscription tiers
- `users` - User accounts with roles
- `user_roles` - Available user roles
- `touchpoints` - CRM activity tracking

See `database_schema.sql` for the complete schema.

## Customization

### Modifying Job Templates

Job templates are stored in ConfigMaps under `configmaps/`. Each template uses Sveltos templating to inject CloudEvent data:

- `{{ .CloudEvent.subject }}` - Customer ID
- `{{ .CloudEvent.data.field_name }}` - Event data fields
- `{{ .CloudEvent.id }}` - Event ID
- `{{ .CloudEvent.time }}` - Event timestamp

### Adding New Event Types

1. Create a new EventSource in `eventsources/`
2. Create a Job template ConfigMap in `configmaps/`
3. Create an EventTrigger in `eventtriggers/`
4. Add sample CloudEvent JSON in `sample-cloudevents/`

## References

- [Sveltos Documentation](https://projectsveltos.github.io/sveltos/)
- [CloudEvents Specification](https://cloudevents.io/)
- [NATS Documentation](https://docs.nats.io/)
- [Sveltos NATS Integration](https://projectsveltos.github.io/sveltos/latest/events/nats/)

## License

See LICENSE file for details.
