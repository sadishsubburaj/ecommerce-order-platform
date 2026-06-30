# Decisions Log

Running log of architecture decisions and the reasoning behind them.
Useful both for resuming work and as interview talking points.

| Date / Day | Decision | Reasoning |
|---|---|---|
| Day 1 | Domain: E-commerce order/inventory/payment platform | Natural fit for race conditions, distributed consistency, idempotency — the concepts we want to demonstrate |
| Day 1 | Start as a monolith, split into services from Day 5 | De-risks early bugs; get business logic correct before adding distributed-systems complexity |
| Day 1 | Single Postgres DB/schema initially | Simplest for monolith phase. Will move to database-per-service (or at least schema-per-service) once split, to keep services independently deployable |
| Day 1 | Inventory kept as a separate table/concept from Products even in monolith | Mirrors the eventual Inventory Service boundary; avoids rework later |
| Day 1 | Saga via choreography (Kafka events), not orchestration | Keeps services decoupled for a learning project; trade-off is harder traceability, solved by adding distributed tracing later |
| Day 1 | order.status state machine: CREATED → INVENTORY_RESERVED → PAYMENT_PENDING → CONFIRMED / FAILED | Gives a clear, testable state machine and a natural place to hook in compensation logic |
| Day 1 | optimistic locking column (`version`) added to inventory table from day 1 | Schema is ready even though locking logic itself is implemented on Day 8 |
| Day 1 | idempotency_key (unique) added to payments table from day 1 | Same reasoning — schema ready ahead of the idempotency logic on Day 9 |
| Day 1 | Kafka with Zookeeper initially, migrate to KRaft mode later | Zookeeper-based setup is still the most common in production systems today and what most interviewers expect; will do a deliberate migration to KRaft (no Zookeeper) later as its own documented step — also gives a good "why we migrated" interview story |

---

## Open questions / revisit later
- Catalog Service: Postgres or MongoDB? (Plan says MongoDB optional — decide on Day 5 based on whether we want to show polyglot persistence)
- Kubernetes manifests: stretch goal for Week 3 if time allows, otherwise document as "future work" in README
