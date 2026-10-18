# Day 5: Security Checklist

| # | Item | Status | Evidence |
|---|------|--------|----------|
| 1 | Least-privilege roles (no app superuser) | Done | `capstone_app` and `capstone_analyst` have `rolsuper = false` and `rolcanlogin = false`. `capstone_app` gets column-level access on `customers`, so it can never read `password_hash`. `capstone_analyst` is read-only. |
| 2 | RLS on every multi-tenant / sensitive table | Done | `relrowsecurity = true` on customers, addresses, orders, order_items, payments, reviews. A customer session sees only its own rows (`app.customer_id`). |
| 3 | Sensitive fields hashed/encrypted | Done | `customers.password_hash` holds bcrypt hashes (`pgcrypto`, prefix `$2a$06$`). No plain-text passwords are stored. |
| 4 | Audit log on critical tables | Done | Triggers on `orders`, `payments`, `products` write old and new rows as JSON to `audit_log`. `customers` is deliberately excluded so password hashes are not copied into the log. |
| 5 | Parameterized queries only | Design rule | See below. |
| 6 | Backups taken AND test restore performed | Done | `backup.bat` creates a dated dump. The dump was restored into `capstone_check`, which returned 1000 customers, 20000 orders and 60000 order items. |

## Item 5: parameterized queries
This project has no application code, so the rule is a design requirement for whatever app connects:
- The app must send SQL and values separately (prepared statements), never build SQL by joining strings with user input.
- Unsafe pattern: `"SELECT * FROM orders WHERE id = " + userInput`.
- Safe pattern: `SELECT * FROM orders WHERE id = $1`, with the value passed as a parameter.
- Defence in depth: even if an injection slipped through, the app role has no superuser rights, cannot read `password_hash`, and RLS limits it to one customer's rows.

## Design decisions worth explaining
- **Composite foreign key** `orders (address_id, customer_id)` makes it impossible to ship an order to another customer's address.
- **`unit_price` on `order_items`** freezes the price at purchase time.
- **Audit function is `SECURITY DEFINER`** so the app role can trigger logging without having direct access to `audit_log`.
- **Roles survive `flyway clean`** (they are cluster-wide), so V4 creates them only if missing.
- **Concurrency-safe checkout (V7):** `place_order()` locks product rows with `SELECT ... FOR UPDATE` in id order (avoids deadlocks), decrements stock only if `stock >= qty`, and inserts the order and items in one transaction. Any failure rolls everything back. It is `SECURITY DEFINER` and takes the customer from the session (`app.customer_id`), so `capstone_app` needs no direct UPDATE on `products`.