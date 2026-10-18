\# E-commerce Capstone (PostgreSQL 18, Redis, Flyway)



An online store database covering the full lifecycle: design, versioned schema, NoSQL layer, optimization, backup and security.



\## Contents

| Path | What it is |

|------|------------|

| `docs/requirements.md` | One-page requirements summary |

| `docs/er-diagram.png` | ER diagram (8 tables, relationships, cardinalities) |

| `migrations/V1` to `V6` | Flyway migrations: tables, indexes, audit and triggers, row-level security, seed data, query indexes |

| `docs/nosql-redis.md` | Redis cart and cache, with justification and evidence |

| `docs/optimization.md` | Before and after `EXPLAIN ANALYZE` evidence |

| `docs/security.md` | Security checklist with evidence |

| `backup.bat` | Dated `pg\_dump` backup script |

| `docs/presentation.md` | Walkthrough outline |



\## How to rebuild from empty

```

flyway -url=jdbc:postgresql://localhost:5432/capstone -user=postgres -password=<password> -locations=filesystem:migrations -cleanDisabled=false clean migrate

```

Result: 5 migrations applied from an empty database (6 now, with `V6\_\_query\_indexes.sql`).



\## Highlights

\- \*\*Optimization:\*\* query 1 went from 24.7 ms to 5.9 ms and query 2 from 9.4 ms to 1.2 ms (Seq Scan to index scans).

\- \*\*Security:\*\* RLS on 6 tables, no password hashes visible to the app role, audit trail on orders, payments and products.

\- \*\*Redis:\*\* cart and product cache with automatic expiry; orders and payments stay in PostgreSQL.

\- \*\*Backup:\*\* dump restored into a separate database and verified by row counts.

