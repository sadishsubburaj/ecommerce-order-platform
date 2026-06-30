# Distributed E-Commerce Order Platform — Build Plan

**Goal:** Build a microservices-based e-commerce order/inventory/payment system to demonstrate senior-level (7+ YOE) Java backend skills, push to GitHub, and use as a resume project while job-hunting.

**Status legend:** [ ] not started · [~] in progress · [x] done

---

## Architecture (target end state)

```
API Gateway (Spring Cloud Gateway)
   │
   ├── User Service         (Auth, JWT, PostgreSQL)
   ├── Catalog Service       (Product CRUD/search, MongoDB or Postgres, Redis cache)
   ├── Order Service         (Order state machine, PostgreSQL)
   ├── Inventory Service      (Stock + optimistic locking, PostgreSQL)
   ├── Payment Service        (Mock gateway, idempotency, PostgreSQL)
   └── Notification Service   (Email/SMS consumer, mocked)

Kafka topics: order.created → inventory.reserved → payment.processed → order.confirmed
              (compensating: order.failed → inventory.release)
Eureka            — service discovery
Spring Cloud Gateway — routing + JWT validation
Resilience4j       — circuit breaker / retry / fallback
Redis             — catalog cache + idempotency key store
Prometheus/Grafana — metrics
Zipkin/Sleuth      — distributed tracing
Docker Compose     — local orchestration
GitHub Actions     — CI (build + test on push)
```

Core interview talking points this is designed to produce:
1. Saga pattern / distributed consistency without 2PC
2. Optimistic locking to prevent overselling under concurrent orders
3. Idempotent payment API (safe retries)
4. Graceful degradation when a downstream service fails (circuit breaker)
5. Real load-test numbers (req/sec, p95 latency) for resume bullets

---

## Week 1 — Core logic, then split into services

- [x] **Day 1 — Setup & domain design**
  - Initialize GitHub repo, folder structure, root README
  - Design DB schema: `users`, `products`, `orders`, `order_items`, `inventory`, `payments`
  - Diagram the order flow: created → inventory reserved → paid → confirmed (or failed → compensated)
  - docker-compose for local Postgres, Redis, Kafka

- [ ] **Day 2 — Monolith skeleton**
  - Single Spring Boot app, package-per-domain (`order`, `inventory`, `payment`)
  - Entity classes + JPA repositories
  - Basic CRUD: create product, place order, check stock

- [ ] **Day 3 — Core business logic**
  - Order placement logic, inventory deduction, mock payment
  - Fully working end-to-end as a monolith (safety net before splitting)

- [ ] **Day 4 — Tests + first GitHub push**
  - JUnit/Mockito tests for order/inventory logic
  - Write real README (what it does, how to run it)
  - Push to GitHub — first applyable link

- [ ] **Day 5 — Extract User & Catalog services**
  - Separate Spring Boot apps for User (auth/JWT) and Catalog (product search)
  - Move relevant tables/logic out of monolith

- [ ] **Day 6 — Extract Order, Inventory, Payment services**
  - Split monolith into 3 services
  - Replace in-process calls with REST via OpenFeign

- [ ] **Day 7 — Service discovery + gateway**
  - Add Eureka, register all services
  - Add Spring Cloud Gateway, route requests through it
  - JWT auth flow across services (gateway validates token)

---

## Week 2 — Concurrency, Kafka, resilience

- [ ] **Day 8 — Optimistic locking**
  - `@Version` on inventory entity
  - Concurrency test: parallel order requests for last unit of stock → only one succeeds

- [ ] **Day 9 — Idempotency**
  - Idempotency key on payment API, store key+result in Redis
  - Test: same request sent twice → processed once

- [ ] **Day 10-11 — Kafka Saga (centerpiece)**
  - Topics: `order.created`, `inventory.reserved`, `payment.processed`, `order.confirmed`, `order.failed`
  - Flow: Order publishes → Inventory consumes/reserves/publishes → Payment consumes/charges/publishes → Order confirms
  - Compensation: payment failure → `inventory.release` event rolls back stock

- [ ] **Day 12 — Resilience4j**
  - Circuit breaker + retry + fallback (Order→Inventory, Order→Payment)
  - Test: kill Payment service, confirm Order degrades gracefully

- [ ] **Day 13 — Redis caching**
  - Cache product catalog reads, invalidate on update
  - Measure before/after latency (resume number)

- [ ] **Day 14 — Notification service**
  - Consumes `order.confirmed`/`order.failed`, logs/mocks email-SMS send
  - Integration test with Testcontainers for Kafka

---

## Week 3 — Observability, DevOps, polish

- [ ] **Day 15 — Dockerize everything**
  - Dockerfile per service, full docker-compose up for all 6 services + infra

- [ ] **Day 16 — Monitoring**
  - Prometheus scraping each service, Grafana dashboard (latency, error rate, throughput)

- [ ] **Day 17 — Tracing**
  - Zipkin/Sleuth across full order flow, screenshot a trace for README

- [ ] **Day 18 — CI/CD**
  - GitHub Actions: build, run tests, build Docker images on push

- [ ] **Day 19 — API docs & load test**
  - Swagger/OpenAPI on each service
  - k6 or JMeter load test → real numbers (req/sec, p95 latency)

- [ ] **Day 20 — README & architecture diagram**
  - Full README: architecture diagram, setup steps, tech decisions, "what I'd improve at scale" section
  - Record a short demo GIF

- [ ] **Day 21 — Buffer + resume update**
  - Fix whatever broke during the week
  - Update resume with final project bullet + real numbers from load test

---

## Parallel track (throughout all 3 weeks)

- Start applying to jobs from end of **Day 4** onward (don't wait for full completion)
- Spend roughly 60% time on project / 40% on applications + interview prep
- Use project concepts (Saga, locking, resilience) to prep system design answers as you build them

---

## Notes / Decisions Log
*(Add entries here as we make architecture decisions, so context isn't lost)*

- Domain chosen: E-commerce order/inventory/payment platform
- Saga style: choreography (Kafka events), not orchestration
- Starting point: monolith first, then split into services (de-risks early bugs)

---

## How to resume if chat history is lost

1. Re-upload this file to a new Claude conversation
2. Mark which days are checked off
3. Say: "Continue the project from Day X" and share current repo state/code if available
