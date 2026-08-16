# Technical Requirements Document (TRD)  -  Campus Companion

**Status:** Draft  -  living document, expand as architecture decisions land.

## Target scale

Free-tier infrastructure, sized for 1,000 baseline / 5,000 peak registered
users on a single campus.

## Stack (as decided so far)

| Layer | Choice | Notes |
|---|---|---|
| Frontend | React + Tailwind CSS | Mobile-first, responsive |
| Auth | Firebase Authentication | College-email domain allowlist at signup |
| Data storage | TBD per module | See "Storage strategy" below |
| Cache / rate limiting | Upstash Redis | Free tier; used for hot-query caching and abuse rate limits (e.g. group join requests, report submissions) |
| Serverless functions | Netlify Functions or Cloudflare Workers | API layer between frontend and data stores |
| Hosting | Netlify or Cloudflare Pages | |
| File storage | TBD (Firebase Storage vs Cloudflare R2) | For listing/event photos |

## Storage strategy  -  open question

The DB schema (see `database-schema.dbml`) is intentionally engine-agnostic.
Two real candidates on the table:

- **Firestore**  -  good fit for auth-bound, low-write-volume, real-time data
  (notifications, RSVPs, live status).
- **Turso/libSQL**  -  good fit for the relational, read-heavy, filterable
  data most modules actually are (goods/service listings, events, exam
  entries), and its SQLite lineage gives cheap full-text search (FTS5)
  that Firestore doesn't have natively.

Given the schema now cleanly separates Services (organizations,
service_listings, applications) from Goods Marketplace and the rest, it's a
legitimate option to put Services on a different DB service than the core
schema if that ends up simplifying the free-tier math  -  flagged as a
decision to make once real usage patterns are known, not before.

## Access control

RBAC is modeled explicitly in the schema (`roles` + `user_roles`), separate
from resource ownership (`club_admins`, `organization_admins`,
`interest_groups.creator_id`, etc.). Role grants are scoped by campus and,
for moderators, by module  -  see the schema notes on `user_roles`.
Enforcement of these roles happens at the application/API layer; the
database does not itself prevent a write that violates a role check.

## Open items

- [ ] Finalize storage engine(s) per module and update this doc
- [ ] Free-tier capacity math per module (reads/writes/day vs quota)
- [ ] Photo storage decision (Firebase Storage vs Cloudflare R2)
- [ ] CI: wire up real lint/build/test scripts in `.github/workflows/ci.yml`
- [ ] Define the seed set of `roles.key` values