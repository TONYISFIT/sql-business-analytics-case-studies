-- ============================================================================
-- schema.sql — E-commerce analytics schema (SYNTHETIC data, for practice)
-- ----------------------------------------------------------------------------
-- Tables: customers, products, orders, order_items
-- Designed to run on SQLite as-is. Also compatible with MySQL and PostgreSQL
-- with trivial type adjustments (INTEGER -> INT, REAL -> NUMERIC, DATE -> DATE).
-- ============================================================================

CREATE TABLE customers (
    customer_id   INTEGER PRIMARY KEY,
    first_name    TEXT NOT NULL,
    last_name     TEXT NOT NULL,
    email         TEXT NOT NULL,
    city          TEXT,
    signup_date   DATE NOT NULL
);

CREATE TABLE products (
    product_id    INTEGER PRIMARY KEY,
    product_name  TEXT NOT NULL,
    category      TEXT NOT NULL,
    unit_price    REAL NOT NULL
);

CREATE TABLE orders (
    order_id      INTEGER PRIMARY KEY,
    customer_id   INTEGER NOT NULL REFERENCES customers (customer_id),
    order_date    DATE NOT NULL,
    status        TEXT NOT NULL DEFAULT 'delivered'
                  CHECK (status IN ('delivered', 'cancelled', 'returned'))
);

CREATE TABLE order_items (
    order_item_id INTEGER PRIMARY KEY,
    order_id      INTEGER NOT NULL REFERENCES orders (order_id),
    product_id    INTEGER NOT NULL REFERENCES products (product_id),
    quantity      INTEGER NOT NULL CHECK (quantity > 0),
    unit_price    REAL NOT NULL CHECK (unit_price >= 0)
);

CREATE INDEX idx_orders_customer ON orders (customer_id);
CREATE INDEX idx_orders_date ON orders (order_date);
CREATE INDEX idx_items_order ON order_items (order_id);
CREATE INDEX idx_items_product ON order_items (product_id);
