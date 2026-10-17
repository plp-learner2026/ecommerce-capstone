-- Roles are cluster-wide and survive "clean", so create them only if missing
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'capstone_app') THEN
    CREATE ROLE capstone_app NOLOGIN;
  END IF;
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'capstone_analyst') THEN
    CREATE ROLE capstone_analyst NOLOGIN;
  END IF;
END $$;

GRANT CONNECT ON DATABASE capstone TO capstone_app, capstone_analyst;
GRANT USAGE ON SCHEMA public TO capstone_app, capstone_analyst;

-- Which customer is acting is passed in as a session setting
CREATE FUNCTION current_customer_id() RETURNS INT
LANGUAGE sql STABLE AS
$$ SELECT NULLIF(current_setting('app.customer_id', true), '')::int $$;

-- Customer-facing app role: least privilege, never sees password_hash
GRANT SELECT ON products, categories TO capstone_app;
GRANT SELECT (id, email, full_name) ON customers TO capstone_app;
GRANT UPDATE (full_name) ON customers TO capstone_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON addresses TO capstone_app;
GRANT SELECT, INSERT, UPDATE ON orders TO capstone_app;
GRANT SELECT, INSERT ON order_items, payments, reviews TO capstone_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO capstone_app;

-- Analyst role: read-only
GRANT SELECT ON products, categories, orders, order_items, payments, reviews
  TO capstone_analyst;

-- Row-level security
ALTER TABLE customers   ENABLE ROW LEVEL SECURITY;
ALTER TABLE addresses   ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders      ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments    ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews     ENABLE ROW LEVEL SECURITY;

CREATE POLICY customers_self ON customers FOR ALL TO capstone_app
  USING (id = current_customer_id());

CREATE POLICY addresses_owner ON addresses FOR ALL TO capstone_app
  USING (customer_id = current_customer_id())
  WITH CHECK (customer_id = current_customer_id());

CREATE POLICY orders_owner ON orders FOR ALL TO capstone_app
  USING (customer_id = current_customer_id())
  WITH CHECK (customer_id = current_customer_id());

CREATE POLICY order_items_owner ON order_items FOR ALL TO capstone_app
  USING (EXISTS (SELECT 1 FROM orders o
                 WHERE o.id = order_items.order_id
                   AND o.customer_id = current_customer_id()))
  WITH CHECK (EXISTS (SELECT 1 FROM orders o
                 WHERE o.id = order_items.order_id
                   AND o.customer_id = current_customer_id()));

CREATE POLICY payments_owner ON payments FOR ALL TO capstone_app
  USING (EXISTS (SELECT 1 FROM orders o
                 WHERE o.id = payments.order_id
                   AND o.customer_id = current_customer_id()))
  WITH CHECK (EXISTS (SELECT 1 FROM orders o
                 WHERE o.id = payments.order_id
                   AND o.customer_id = current_customer_id()));

CREATE POLICY reviews_read ON reviews FOR SELECT
  TO capstone_app, capstone_analyst USING (true);
CREATE POLICY reviews_insert ON reviews FOR INSERT TO capstone_app
  WITH CHECK (customer_id = current_customer_id());

CREATE POLICY orders_analyst ON orders FOR SELECT TO capstone_analyst USING (true);
CREATE POLICY order_items_analyst ON order_items FOR SELECT TO capstone_analyst USING (true);
CREATE POLICY payments_analyst ON payments FOR SELECT TO capstone_analyst USING (true);

-- The audit trigger must be able to write to audit_log for any user,
-- without giving the app role direct access to that table
ALTER FUNCTION audit() SECURITY DEFINER SET search_path = public, pg_temp;
ALTER TABLE audit_log ALTER COLUMN changed_by SET DEFAULT session_user;