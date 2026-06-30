# Distributed E-Commerce Order Platform

A microservices-based order/inventory/payment platform built to demonstrate
production-grade backend engineering: distributed transactions (Saga),
concurrency control, idempotency, resilience, observability, and CI/CD.

> Status: 🚧 Under active development. See [PLAN.md](./PLAN.md) for the build plan and progress.

## Why this project

This started as a monolith and is being incrementally split into services to
mirror how a real system evolves — and to make sure the core business logic
is correct before distributed-systems complexity is layered on top.

The system intentionally includes the failure modes that matter in production:
- Two customers racing for the last unit of stock
- A payment request retried by a flaky client
- A downstream service going down mid-request

## Architecture (target state)

See [docs/order-flow.md](./docs/order-flow.md) for the full saga sequence diagrams.

```
API Gateway
   ├── User Service        — auth, JWT
   ├── Catalog Service      — products, search, Redis cache
   ├── Order Service        — order lifecycle / state machine
   ├── Inventory Service     — stock, optimistic locking
   ├── Payment Service        — mock payment, idempotency
   └── Notification Service   — async notifications

Kafka — event backbone for the order saga
Eureka — service discovery
Resilience4j — circuit breaker / retry
Prometheus + Grafana — metrics
Zipkin — distributed tracing
```

## Tech stack

Java 17, Spring Boot, Spring Cloud (Gateway, Eureka, OpenFeign), PostgreSQL,
Redis, Apache Kafka, Resilience4j, Docker / Docker Compose, GitHub Actions.

## Running locally

```bash
docker compose up -d
```

This starts Postgres, Redis, Kafka (+ Zookeeper), and a Kafka UI at
`http://localhost:8090`. Service-specific run instructions will be added as
each service is built.

## Documentation

- [PLAN.md](./PLAN.md) — day-by-day build plan and progress checklist
- [docs/order-flow.md](./docs/order-flow.md) — saga sequence diagrams, state machine
- [docs/decisions.md](./docs/decisions.md) — architecture decisions log

## Roadmap

See [PLAN.md](./PLAN.md) for the full 3-week, day-by-day plan.
