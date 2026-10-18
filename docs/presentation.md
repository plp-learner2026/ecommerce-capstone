\# Walkthrough Presentation: E-commerce Capstone (about 5 minutes)



1\. \*\*Problem and requirements\*\* (30 s): an online store; customers, products, orders, payments, reviews. Show `er-diagram.png`.

2\. \*\*Schema as migrations\*\* (60 s): V1 to V6; show `flyway clean migrate` rebuilding the database from empty. Mention the composite foreign key and CHECK constraints.

3\. \*\*Redis layer\*\* (45 s): carts and cache are temporary and change constantly, so Redis with `EXPIRE`; orders stay in PostgreSQL.

4\. \*\*Optimization\*\* (60 s): show one before and after plan (24.7 ms to 5.9 ms, Seq Scan to Bitmap Index Scan) and one that went 9.4 ms to 1.2 ms.

5\. \*\*Security\*\* (60 s): least-privilege roles, row-level security demo (customer 5 sees only their own orders), bcrypt hashes, audit trail.

6\. \*\*Backup and restore\*\* (30 s): dated dump, test restore with matching row counts.

7\. \*\*What I would do next\*\* (15 s): connect an application using parameterized queries, add MongoDB or Redis persistence if needed, and schedule `backup.bat`.

