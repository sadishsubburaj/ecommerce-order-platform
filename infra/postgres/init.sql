-- ============================================================
-- E-Commerce Order Platform — Initial Schema (Day 1)
-- Single database for now (monolith phase).
-- When we split into services (Day 5-6), each service will
-- get its own schema/database — see docs/decisions.md.
-- ============================================================

CREATE TABLE IF NOT EXISTS users (
    id              BIGSERIAL PRIMARY KEY,
    email           VARCHAR(255) NOT NULL UNIQUE,
    password_hash   VARCHAR(255) NOT NULL,
    full_name       VARCHAR(255) NOT NULL,
    role            VARCHAR(50)  NOT NULL DEFAULT 'CUSTOMER', -- CUSTOMER, ADMIN
    created_at      TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS products (
    id              BIGSERIAL PRIMARY KEY,
    sku             VARCHAR(64) NOT NULL UNIQUE,
    name            VARCHAR(255) NOT NULL,
    description     TEXT,
    price           NUMERIC(12, 2) NOT NULL CHECK (price >= 0),
    created_at      TIMESTAMP NOT NULL DEFAULT now(),
    updated_at      TIMESTAMP NOT NULL DEFAULT now()
);

-- Inventory is kept separate from products so the Inventory
-- service can own stock/concurrency concerns independently.
CREATE TABLE IF NOT EXISTS inventory (
    id              BIGSERIAL PRIMARY KEY,
    product_id      BIGINT NOT NULL REFERENCES products(id),
    available_qty   INTEGER NOT NULL CHECK (available_qty >= 0),
    reserved_qty    INTEGER NOT NULL DEFAULT 0 CHECK (reserved_qty >= 0),
    version         BIGINT NOT NULL DEFAULT 0,   -- optimistic locking (Day 8)
    updated_at      TIMESTAMP NOT NULL DEFAULT now(),
    UNIQUE (product_id)
);

CREATE TABLE IF NOT EXISTS orders (
    id              BIGSERIAL PRIMARY KEY,
    user_id         BIGINT NOT NULL REFERENCES users(id),
    status          VARCHAR(30) NOT NULL DEFAULT 'CREATED',
        -- CREATED -> INVENTORY_RESERVED -> PAYMENT_PENDING -> CONFIRMED
        --                                                  -> FAILED (compensated)
    total_amount    NUMERIC(12, 2) NOT NULL CHECK (total_amount >= 0),
    created_at      TIMESTAMP NOT NULL DEFAULT now(),
    updated_at      TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS order_items (
    id              BIGSERIAL PRIMARY KEY,
    order_id        BIGINT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id      BIGINT NOT NULL REFERENCES products(id),
    quantity        INTEGER NOT NULL CHECK (quantity > 0),
    unit_price      NUMERIC(12, 2) NOT NULL CHECK (unit_price >= 0)
);

CREATE TABLE IF NOT EXISTS payments (
    id              BIGSERIAL PRIMARY KEY,
    order_id        BIGINT NOT NULL REFERENCES orders(id),
    idempotency_key VARCHAR(128) NOT NULL UNIQUE,   -- Day 9
    amount          NUMERIC(12, 2) NOT NULL CHECK (amount >= 0),
    status          VARCHAR(30) NOT NULL DEFAULT 'PENDING', -- PENDING, SUCCESS, FAILED
    created_at      TIMESTAMP NOT NULL DEFAULT now()
);

-- Helpful indexes
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_inventory_product_id ON inventory(product_id);
CREATE INDEX IF NOT EXISTS idx_payments_order_id ON payments(order_id);

-- Seed a couple of products + inventory for local testing
INSERT INTO products (sku, name, description, price) VALUES
    ('SKU-001', 'Wireless Mouse', 'Ergonomic wireless mouse', 799.00),
    ('SKU-002', 'Mechanical Keyboard', 'RGB mechanical keyboard', 3499.00),
    ('SKU-003', 'USB-C Hub', '7-in-1 USB-C hub', 1299.00)
ON CONFLICT (sku) DO NOTHING;

INSERT INTO inventory (product_id, available_qty)
SELECT id, 50 FROM products
ON CONFLICT (product_id) DO NOTHING;
