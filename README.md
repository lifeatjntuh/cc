# Campus Companion

A student-built, student-owned super app for campus life  -  Marketplace
(goods), Services & Gigs, Events, Attendance, Exams, Interest Circles, and a
Campus Creators directory  -  designed to run entirely independent of
university IT, SSO, or administrative buy-in.

> **License note:** this project is **source-available, not open source**
> in the strict OSI sense  -  the code is public, but commercial use and
> redistribution are prohibited. See [LICENSE](./LICENSE).

## Repo layout

```
campus-companion/
|-- apps/
|   |-- web/            React + Tailwind frontend
|   `-- functions/      Serverless API layer (Netlify / Cloudflare Functions)
|-- packages/
|   `-- shared/         Shared types, constants, and schema definitions
|-- docs/
|   |-- PRD.md                    Product requirements
|   |-- TRD.md                    Technical requirements / architecture
|   `-- database-schema.dbml      DB schema (import at drawdb.app)
|-- .github/             Issue/PR templates, workflows, CODEOWNERS
|-- CONTRIBUTING.md
|-- CODE_OF_CONDUCT.md
|-- SECURITY.md
`-- LICENSE
```

## Tech stack (target  -  see docs/TRD.md for the full rationale)

- **Frontend:** React + Tailwind CSS
- **Auth:** Firebase Authentication (college-email allowlist)
- **Primary data store:** to be finalized per-module (see docs/TRD.md)  - 
  candidates include Firestore and Turso/libSQL
- **Cache / rate limiting:** Upstash Redis
- **Serverless functions:** Netlify Functions or Cloudflare Workers
- **Hosting:** Netlify or Cloudflare Pages

All infrastructure choices are made to stay within free-tier limits for a
single campus of roughly 1,000-5,000 users.

## Getting started

```bash
npm install
npm run dev --workspace=apps/web
```

(This is a scaffold  -  app code is not implemented yet. See docs/PRD.md and
docs/TRD.md for what's planned.)

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md). Please read the
[Code of Conduct](./CODE_OF_CONDUCT.md) before opening issues or PRs.

## Security

See [SECURITY.md](./SECURITY.md) for how to report vulnerabilities.

## License

[Campus Companion Source-Available Non-Commercial License](./LICENSE)  - 
public source, no commercial use, no redistribution.