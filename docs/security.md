\# Day 5: Security Checklist



| # | Item | Status | Evidence |

|---|------|--------|----------|

| 1 | Least-privilege roles (no app superuser) | Done | `capstone\_app` and `capstone\_analyst` have `rolsuper = false` and `rolcanlogin = false`. `capstone\_app` gets column-level access on `customers`, so it can never read `password\_hash`. `capstone\_analyst` is read-only. |

| 2 | RLS on every multi-tenant / sensitive table | Done | `relrowsecurity = true` on customers, addresses, orders, order\_items, payments, reviews. A customer session sees only its own rows (`app.customer\_id`). |

| 3 | Sensitive fields hashed/encrypted | Done | `customers.password\_hash` holds bcrypt hashes (`pgcrypto`, prefix `$2a$06$`). No plain-text passwords are stored. |

| 4 | Audit log on critical tables | Done | Triggers on `orders`, `payments`, `products` write old and new rows as JSON to `audit\_log`. `customers` is deliberately excluded so password hashes are not copied into the log. |

| 5 | Parameterized queries only | Design rule | See below. |

| 6 | Backups taken AND test restore performed | Done | `backup.bat` creates a dated dump. The dump was restored into `capstone\_check`, which returned 1000 customers, 20000 orders and 60000 order items. |



\## Item 5: parameterized queries

This project has no application code, so the rule is a design requirement for whatever app connects:

\- The app must send SQL and values separately (prepared statements), never build SQL by joining strings with user input.

\- Unsafe pattern: `"SELECT \* FROM orders WHERE id = " + userInput`.

\- Safe pattern: `SELECT \* FROM orders WHERE id = $1`, with the value passed as a parameter.

\- Defence in depth: even if an injection slipped through, the app role has no superuser rights, cannot read `password\_hash`, and RLS limits it to one customer's rows.



\## Design decisions worth explaining

\- \*\*Composite foreign key\*\* `orders (address\_id, customer\_id)` makes it impossible to ship an order to another customer's address.

\- \*\*`unit\_price` on `order\_items`\*\* freezes the price at purchase time.

\- \*\*Audit function is `SECURITY DEFINER`\*\* so the app role can trigger logging without having direct access to `audit\_log`.

\- \*\*Roles survive `flyway clean`\*\* (they are cluster-wide), so V4 creates them only if missing.

