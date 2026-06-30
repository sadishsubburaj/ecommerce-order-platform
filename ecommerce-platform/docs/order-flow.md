# Order Flow — Saga (Choreography via Kafka)

## Happy path

```mermaid
sequenceDiagram
    participant C as Client
    participant O as Order Service
    participant I as Inventory Service
    participant P as Payment Service
    participant N as Notification Service
    participant K as Kafka

    C->>O: POST /orders
    O->>O: Create order (status=CREATED)
    O->>K: publish order.created
    K->>I: consume order.created
    I->>I: Reserve stock (optimistic lock)
    I->>K: publish inventory.reserved
    K->>P: consume inventory.reserved
    P->>P: Charge payment (idempotency key)
    P->>K: publish payment.processed
    K->>O: consume payment.processed
    O->>O: status=CONFIRMED
    O->>K: publish order.confirmed
    K->>N: consume order.confirmed
    N->>N: Send confirmation email/SMS
```

## Failure / compensation path (payment fails)

```mermaid
sequenceDiagram
    participant O as Order Service
    participant I as Inventory Service
    participant P as Payment Service
    participant K as Kafka

    Note over O,P: ...order.created -> inventory.reserved already happened...
    K->>P: consume inventory.reserved
    P->>P: Charge payment FAILS
    P->>K: publish payment.failed
    K->>O: consume payment.failed
    O->>O: status=FAILED
    O->>K: publish order.failed
    K->>I: consume order.failed
    I->>I: Release reserved stock (compensating action)
```

## Order status state machine

```
CREATED ──► INVENTORY_RESERVED ──► PAYMENT_PENDING ──► CONFIRMED
   │                │                     │
   └────────────────┴─────────────────────┴──► FAILED (compensated)
```

## Why choreography over orchestration

We're using event choreography (each service reacts to events and publishes the next one)
rather than a central orchestrator, to keep services decoupled and avoid a single point of
failure/bottleneck in a learning-focused project. Trade-off: harder to trace a single order's
journey without distributed tracing — which is exactly why we add Zipkin/Sleuth in Week 3.
If this were a larger real-world system with many more steps, an orchestrator
(e.g. Camunda, or a custom Order Saga coordinator) would likely be easier to reason about
and debug — worth mentioning as a trade-off in interviews.
