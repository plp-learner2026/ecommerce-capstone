CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Skip the audit triggers while bulk loading demo data
ALTER TABLE orders   DISABLE TRIGGER trg_audit_orders;
ALTER TABLE payments DISABLE TRIGGER trg_audit_payments;
ALTER TABLE products DISABLE TRIGGER trg_audit_products;

INSERT INTO categories (name, parent_id)
SELECT 'Category ' || g, NULL FROM generate_series(1, 5) g;

INSERT INTO categories (name, parent_id)
SELECT 'Subcategory ' || g, ((g - 1) % 5) + 1 FROM generate_series(1, 15) g;

WITH h AS (SELECT crypt('demo-password', gen_salt('bf', 6)) AS p)
INSERT INTO customers (email, password_hash, full_name, created_at)
SELECT 'user' || g || '@example.com', h.p, 'Customer ' || g,
       now() - make_interval(days => (random() * 365)::int)
FROM generate_series(1, 1000) g, h;

INSERT INTO addresses (customer_id, line1, city, country)
SELECT g, 'Street ' || g,
       (ARRAY['Mombasa','Nairobi','Kisumu','Nakuru'])[1 + g % 4], 'Kenya'
FROM generate_series(1, 1000) g;

INSERT INTO products (category_id, name, price, stock)
SELECT 6 + (g % 15), 'Product ' || g,
       round((5 + random() * 495)::numeric, 2), (random() * 200)::int
FROM generate_series(1, 500) g;

INSERT INTO orders (customer_id, address_id, status, ordered_at)
SELECT c, c,
       (ARRAY['pending','paid','shipped','delivered','cancelled'])[1 + g % 5],
       now() - make_interval(days => (random() * 180)::int)
FROM (SELECT g, 1 + (g % 1000) AS c FROM generate_series(1, 20000) g) s;

INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT o.id, p.id, 1 + (random() * 4)::int, p.price
FROM orders o
CROSS JOIN (VALUES (1), (7), (13)) AS k(m)
JOIN products p ON p.id = 1 + ((o.id * k.m) % 500);

INSERT INTO payments (order_id, amount, method, paid_at)
SELECT o.id, sum(i.quantity * i.unit_price),
       (ARRAY['card','mpesa','paypal'])[1 + o.id % 3],
       o.ordered_at + interval '1 hour'
FROM orders o
JOIN order_items i ON i.order_id = o.id
WHERE o.status IN ('paid','shipped','delivered')
GROUP BY o.id, o.ordered_at;

INSERT INTO reviews (product_id, customer_id, rating, comment)
SELECT 1 + ((g * 7) % 500), g, 1 + g % 5, 'Demo review ' || g
FROM generate_series(1, 1000) g;

ALTER TABLE orders   ENABLE TRIGGER trg_audit_orders;
ALTER TABLE payments ENABLE TRIGGER trg_audit_payments;
ALTER TABLE products ENABLE TRIGGER trg_audit_products;