#Requires -Version 5.1
<#
.SYNOPSIS
    Scaffolds the Campus Companion monorepo IN PLACE, inside an already-open
    git repo root: folder structure, docs, license, and a full set of
    GitHub community/health files and workflows.

.DESCRIPTION
    Run this from your existing repo root (it's normally launched via the
    accompanying setup-repo.bat, which sets the working directory for you).
    It writes files into the CURRENT directory, detects the existing .git
    folder (so it will NOT re-run `git init`), and stages + commits the new
    files. It does NOT push anywhere  -  you push manually when ready:
      git remote add origin <url>  &&  git push -u origin main

.PARAMETER ProjectPath
    Where to scaffold files. Defaults to "." (the current directory  -  your
    already-open repo root).

.PARAMETER SourceDocsPath
    Folder to look in for PRD.md and campus_companion_schema.dbml. If found,
    they're copied into docs/. If not found, placeholder stubs are created
    instead so nothing is left missing. Defaults to ".".

.PARAMETER RemoteUrl
    Optional. If supplied, adds it as the "origin" remote (git remote add),
    but does NOT push. Skip it if the repo already has a remote set.

.PARAMETER SkipGit
    Switch. Skip git add/commit entirely and just create files.

.EXAMPLE
    .\Setup-CampusCompanionRepo.ps1
    .\Setup-CampusCompanionRepo.ps1 -SourceDocsPath "$HOME\Downloads"
    .\Setup-CampusCompanionRepo.ps1 -RemoteUrl "https://github.com/yourname/campus-companion.git"
#>

[CmdletBinding()]
param(
    [string]$ProjectPath = ".",
    [string]$SourceDocsPath = ".",
    [string]$RemoteUrl = "",
    [switch]$SkipGit
)

$ErrorActionPreference = "Stop"

function Write-Section($text) {
    Write-Host ""
    Write-Host "==> $text" -ForegroundColor Cyan
}

function New-RepoFile {
    param(
        [Parameter(Mandatory)][string]$RelativePath,
        [Parameter(Mandatory)][string]$Content
    )
    $fullPath = Join-Path $Root $RelativePath
    $dir = Split-Path $fullPath -Parent
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    Set-Content -LiteralPath $fullPath -Value $Content -Encoding utf8 -NoNewline
    Write-Host "  created $RelativePath"
}

Write-Section "Campus Companion  -  repo scaffold (in-place)"

$Root = (New-Item -ItemType Directory -Path $ProjectPath -Force).FullName
Write-Host "Scaffolding into: $Root"
if (Test-Path (Join-Path $Root ".git")) {
    Write-Host "  existing .git detected  -  will NOT re-init, will add/commit into it"
} else {
    Write-Warning "No .git folder found here. This doesn't look like a git repo root yet."
}

# ---------------------------------------------------------------------------
# LICENSE
# ---------------------------------------------------------------------------
Write-Section "Writing LICENSE (source-available, non-commercial, no redistribution)"

$licenseContent = @'
Campus Companion Source-Available Non-Commercial License (v1.0)

Copyright (c) 2026 Campus Companion contributors. All rights reserved.

NOTE ON TERMINOLOGY: This is a "source-available" license, not an Open
Source Initiative (OSI) approved open-source license. The OSI definition of
open source requires that redistribution be permitted; this license does
not permit redistribution. The source code is public and viewable on
GitHub, and community contributions are welcome under the terms below, but
usage rights are intentionally restricted.

1. GRANT OF RIGHTS
   Subject to the restrictions in Section 2, you are granted a limited,
   worldwide, royalty-free, non-exclusive, non-transferable license to:
     a) view, study, and run the source code for personal, educational,
        or internal non-commercial evaluation purposes; and
     b) modify the source code locally and submit contributions back to
        this project's official repository via pull request.

2. RESTRICTIONS
   You may NOT, without prior written permission from the copyright holders:
     a) use this software, in whole or in part, for any commercial purpose,
        including but not limited to selling it, offering it as a paid or
        ad-supported service, or using it within a commercial product;
     b) redistribute, publish, sublicense, rehost, or mirror this software
        or any derivative of it, in source or compiled form, outside of
        contributing back to the official repository;
     c) deploy a public or private instance of this software for use by
        any organization or user base other than the original project's
        own deployment(s); or
     d) remove or alter this license notice from any copy of the software.

3. CONTRIBUTIONS
   By submitting a pull request or other contribution to this repository,
   you agree that your contribution is licensed to the project under these
   same terms, and you grant the project maintainers the rights necessary
   to include, modify, and distribute your contribution as part of the
   project under this license.

4. NO WARRANTY
   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
   OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
   MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NONINFRINGEMENT.
   IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
   CLAIM, DAMAGES, OR OTHER LIABILITY ARISING FROM THE SOFTWARE OR ITS USE.

5. TERMINATION
   This license terminates automatically if you violate any of its terms.
   Upon termination you must stop all use of the software.

6. CONTACT
   For commercial licensing, redistribution rights, or any use outside the
   scope of this license, contact the project maintainers (add contact
   details in README.md).
'@
New-RepoFile -RelativePath "LICENSE" -Content $licenseContent

# ---------------------------------------------------------------------------
# README
# ---------------------------------------------------------------------------
Write-Section "Writing README.md"

$readmeContent = @'
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
'@
New-RepoFile -RelativePath "README.md" -Content $readmeContent

# ---------------------------------------------------------------------------
# CONTRIBUTING / CODE_OF_CONDUCT / SECURITY / CHANGELOG
# ---------------------------------------------------------------------------
Write-Section "Writing community health files"

$contributingContent = @'
# Contributing to Campus Companion

Thanks for wanting to help build this. A few ground rules:

## Before you start

- Check open [Issues](../../issues) and [Discussions](../../discussions)
  first  -  someone may already be working on it.
- For anything non-trivial, open an issue to discuss the approach before
  writing code.
- By contributing, you agree your contribution is licensed under this
  project's [LICENSE](./LICENSE) (source-available, non-commercial).

## Workflow

1. Fork the repo and create a branch off `main`:
   `git checkout -b feature/short-description`
2. Make your change. Keep commits focused and messages descriptive.
3. Run any relevant checks locally before opening a PR.
4. Open a pull request using the PR template  -  link the issue it resolves.
5. A maintainer will review; expect requested changes on most PRs.

## Code style

- Follow the existing formatting/linting config in each workspace
  (`apps/web`, `apps/functions`, `packages/shared`).
- Keep PRs scoped to one concern  -  separate refactors from feature work.

## Commit messages

Prefer [Conventional Commits](https://www.conventionalcommits.org/)
(`feat:`, `fix:`, `docs:`, `chore:`, etc.)  -  it keeps the changelog easy to
generate later.

## Reporting bugs / requesting features

Use the issue templates under **New Issue**  -  they ask for the context
maintainers actually need (repro steps for bugs, problem statement for
features).
'@
New-RepoFile -RelativePath "CONTRIBUTING.md" -Content $contributingContent

$codeOfConductContent = @'
# Code of Conduct

## Our commitment

We want Campus Companion to be a welcoming space for students to
contribute, regardless of experience level, background, or which campus
they're from. We're building tools for students, by students  -  that spirit
extends to how we treat each other here.

## Expected behavior

- Be respectful and constructive in issues, PRs, and discussions.
- Assume good faith; ask questions before assuming bad intent.
- Give specific, actionable feedback on code and proposals  -  critique the
  work, not the person.
- Respect maintainers' time: search before filing duplicate issues, keep
  PRs focused, and be patient during review.

## Unacceptable behavior

- Harassment, discriminatory jokes or language, or personal attacks.
- Publishing others' private information without consent.
- Sustained disruption of discussions, issues, or PRs.
- Any conduct that would be inappropriate in a professional setting.

## Enforcement

Maintainers may remove comments, close issues/PRs, or block contributors
who violate this Code of Conduct. Report concerns privately to the
maintainers (see contact details in README.md or SECURITY.md). Reports will
be handled discreetly.

## Scope

This applies within all project spaces (issues, PRs, discussions) and in
public spaces when someone is representing the project.
'@
New-RepoFile -RelativePath "CODE_OF_CONDUCT.md" -Content $codeOfConductContent

$securityContent = @'
# Security Policy

## Reporting a vulnerability

If you find a security issue (e.g. an auth bypass, a way to see another
student's private data, an injection vector), please **do not** open a
public issue.

Instead:

1. Use GitHub's [private vulnerability reporting](../../security/advisories/new)
   (Security tab -> Report a vulnerability), if enabled on this repo, or
2. Email the maintainers directly (add contact address in README.md).

Please include:

- A clear description of the vulnerability and its impact.
- Steps to reproduce (or a proof of concept).
- Any suggested fix, if you have one.

## What to expect

- Acknowledgement within a few days.
- We'll keep you updated as we investigate and fix.
- Credit in the release notes, if you'd like it, once the fix ships.

## Scope

Given this is a student-run project handling student PII (contact details,
attendance, exam data), please prioritize reporting anything that exposes:

- Another user's phone/email/Instagram without their consent.
- Private attendance or exam-subscription data.
- Ability to bypass the college-email signup gate.
- Ability to escalate privileges (e.g. grant yourself a moderator role).
'@
New-RepoFile -RelativePath "SECURITY.md" -Content $securityContent

$changelogContent = @'
# Changelog

All notable changes to this project are documented here.
Format loosely follows [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

### Added
- Initial repo scaffold: monorepo structure, docs, GitHub community files,
  and CI workflow placeholders.
'@
New-RepoFile -RelativePath "CHANGELOG.md" -Content $changelogContent

# ---------------------------------------------------------------------------
# Editor / git config files
# ---------------------------------------------------------------------------
Write-Section "Writing editor and git config files"

$editorConfigContent = @'
root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true
indent_style = space
indent_size = 2

[*.md]
trim_trailing_whitespace = false

[*.py]
indent_size = 4
'@
New-RepoFile -RelativePath ".editorconfig" -Content $editorConfigContent

$gitAttributesContent = @'
* text=auto eol=lf
*.png binary
*.jpg binary
*.jpeg binary
*.ico binary
'@
New-RepoFile -RelativePath ".gitattributes" -Content $gitAttributesContent

$gitIgnoreContent = @'
# Dependencies
node_modules/
.pnp/
.pnp.js

# Build output
dist/
build/
.next/
out/

# Env files
.env
.env.local
.env.*.local

# Logs
npm-debug.log*
yarn-debug.log*
yarn-error.log*
*.log

# Editor/OS
.vscode/*
!.vscode/extensions.json
.idea/
.DS_Store
Thumbs.db

# Firebase
.firebase/
firebase-debug.log
firestore-debug.log

# Misc
*.local
coverage/
'@
New-RepoFile -RelativePath ".gitignore" -Content $gitIgnoreContent

# ---------------------------------------------------------------------------
# GitHub community/health files + workflows
# ---------------------------------------------------------------------------
Write-Section "Writing .github/ templates and workflows"

$bugReportContent = @'
---
name: Bug report
about: Something isn't working as expected
title: "[Bug] "
labels: bug
---

**Describe the bug**
A clear description of what's wrong.

**Steps to reproduce**
1. Go to '...'
2. Do '...'
3. See error

**Expected behavior**
What you expected to happen instead.

**Screenshots**
If applicable.

**Environment**
- Module affected: (Goods Marketplace / Services / Events / Attendance / Exams / Interest Circles / Creators / other)
- Device/browser:
- App version or commit hash:

**Additional context**
Anything else useful.
'@
New-RepoFile -RelativePath ".github/ISSUE_TEMPLATE/bug_report.md" -Content $bugReportContent

$featureRequestContent = @'
---
name: Feature request
about: Suggest an idea for this project
title: "[Feature] "
labels: enhancement
---

**Which module does this relate to?**
(Goods Marketplace / Services / Events / Attendance / Exams / Interest Circles / Creators / cross-cutting / other)

**What problem does this solve?**
A clear description of the problem or gap.

**Describe the solution you'd like**
What you want to happen.

**Describe alternatives you've considered**
Any alternative solutions or features you've thought about.

**Additional context**
Mockups, links, related issues, etc.
'@
New-RepoFile -RelativePath ".github/ISSUE_TEMPLATE/feature_request.md" -Content $featureRequestContent

$issueConfigContent = @'
blank_issues_enabled: false
contact_links:
  - name: Ask a question / discuss an idea
    url: https://github.com/OWNER/REPO/discussions
    about: Use Discussions for open-ended questions instead of an issue.
'@
New-RepoFile -RelativePath ".github/ISSUE_TEMPLATE/config.yml" -Content $issueConfigContent

$prTemplateContent = @'
## What does this PR do?

Briefly describe the change and link the issue it resolves (e.g. `Closes #12`).

## Which module(s) does this touch?

- [ ] Goods Marketplace
- [ ] Services & Gigs
- [ ] Events
- [ ] Attendance
- [ ] Exams
- [ ] Interest Circles
- [ ] Campus Creators
- [ ] Shared / cross-cutting (auth, identity, notifications, roles)
- [ ] Docs only

## How was this tested?

Describe how you verified the change works.

## Checklist

- [ ] I've read [CONTRIBUTING.md](../CONTRIBUTING.md)
- [ ] My code follows the existing style/lint config
- [ ] I've updated docs/comments where relevant
- [ ] I've added/updated tests where relevant
- [ ] This PR is scoped to one concern (not mixing refactors with features)
'@
New-RepoFile -RelativePath ".github/PULL_REQUEST_TEMPLATE.md" -Content $prTemplateContent

$codeownersContent = @'
# Default owners for everything in the repo, unless a later match takes
# precedence. Replace with real GitHub usernames/teams once set up.

*                       @OWNER

/apps/web/              @OWNER
/apps/functions/        @OWNER
/packages/shared/       @OWNER
/docs/                  @OWNER
/.github/               @OWNER
'@
New-RepoFile -RelativePath ".github/CODEOWNERS" -Content $codeownersContent

$dependabotContent = @'
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/apps/web"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 5

  - package-ecosystem: "npm"
    directory: "/apps/functions"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 5

  - package-ecosystem: "npm"
    directory: "/packages/shared"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 5

  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
'@
New-RepoFile -RelativePath ".github/dependabot.yml" -Content $dependabotContent

$labelerConfigContent = @'
"module: goods-marketplace":
  - changed-files:
      - any-glob-to-any-file: "apps/web/src/features/goods-marketplace/**"

"module: services":
  - changed-files:
      - any-glob-to-any-file: "apps/web/src/features/services/**"

"module: events":
  - changed-files:
      - any-glob-to-any-file: "apps/web/src/features/events/**"

"module: attendance":
  - changed-files:
      - any-glob-to-any-file: "apps/web/src/features/attendance/**"

"module: exams":
  - changed-files:
      - any-glob-to-any-file: "apps/web/src/features/exams/**"

"module: interest-circles":
  - changed-files:
      - any-glob-to-any-file: "apps/web/src/features/interest-circles/**"

"module: creators":
  - changed-files:
      - any-glob-to-any-file: "apps/web/src/features/creators/**"

"docs":
  - changed-files:
      - any-glob-to-any-file: "docs/**"

"dependencies":
  - changed-files:
      - any-glob-to-any-file: "**/package.json"
'@
New-RepoFile -RelativePath ".github/labeler.yml" -Content $labelerConfigContent

$ciWorkflowContent = @'
name: CI

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

jobs:
  lint-and-build:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node-version: [20.x]
    steps:
      - uses: actions/checkout@v4

      - name: Set up Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
          cache: "npm"

      - name: Install dependencies
        run: npm install

      - name: Lint (placeholder  -  wire up real lint script per workspace)
        run: echo "TODO: npm run lint --workspaces"

      - name: Build (placeholder  -  wire up real build script per workspace)
        run: echo "TODO: npm run build --workspaces"
'@
New-RepoFile -RelativePath ".github/workflows/ci.yml" -Content $ciWorkflowContent

$labelerWorkflowContent = @'
name: Pull Request Labeler

on:
  pull_request_target:
    types: [opened, synchronize]

permissions:
  contents: read
  pull-requests: write

jobs:
  label:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/labeler@v5
        with:
          configuration-path: .github/labeler.yml
'@
New-RepoFile -RelativePath ".github/workflows/labeler.yml" -Content $labelerWorkflowContent

$staleWorkflowContent = @'
name: Mark stale issues and PRs

on:
  schedule:
    - cron: "0 3 * * *"
  workflow_dispatch:

jobs:
  stale:
    runs-on: ubuntu-latest
    permissions:
      issues: write
      pull-requests: write
    steps:
      - uses: actions/stale@v9
        with:
          days-before-stale: 45
          days-before-close: 14
          stale-issue-message: >
            This issue has been inactive for 45 days and will be closed in
            14 days if there's no further activity. Comment if it's still
            relevant.
          stale-pr-message: >
            This PR has been inactive for 45 days and will be closed in 14
            days if there's no further activity.
          stale-issue-label: "stale"
          stale-pr-label: "stale"
          exempt-issue-labels: "pinned,security"
          exempt-pr-labels: "pinned"
'@
New-RepoFile -RelativePath ".github/workflows/stale.yml" -Content $staleWorkflowContent

# ---------------------------------------------------------------------------
# Docs (PRD / TRD / DB schema)  -  copy from source if present, else stub
# ---------------------------------------------------------------------------
Write-Section "Setting up docs/ (copying PRD/schema if found, else creating stubs)"

$prdSourceCandidate = Join-Path $SourceDocsPath "PRD.md"
if (Test-Path $prdSourceCandidate) {
    Copy-Item -LiteralPath $prdSourceCandidate -Destination (Join-Path $Root "docs\PRD.md") -Force
    Write-Host "  copied PRD.md from $SourceDocsPath"
} else {
    $prdStub = @'
# Product Requirements Document (PRD)  -  TODO

This is a placeholder. Paste in the full PRD (Campus Companion  -  Product
Requirements Document) here, or re-run the scaffold script with
`-SourceDocsPath` pointing at the folder where you saved PRD.md.
'@
    New-RepoFile -RelativePath "docs/PRD.md" -Content $prdStub
}

$schemaSourceCandidate = Join-Path $SourceDocsPath "campus_companion_schema.dbml"
if (Test-Path $schemaSourceCandidate) {
    Copy-Item -LiteralPath $schemaSourceCandidate -Destination (Join-Path $Root "docs\database-schema.dbml") -Force
    Write-Host "  copied campus_companion_schema.dbml from $SourceDocsPath"
} else {
    $schemaStub = @'
// Database schema  -  TODO
// Paste in the DBML schema here, or re-run the scaffold script with
// -SourceDocsPath pointing at the folder where you saved
// campus_companion_schema.dbml. Import at https://drawdb.app/editor
'@
    New-RepoFile -RelativePath "docs/database-schema.dbml" -Content $schemaStub
}

$trdContent = @'
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
'@
New-RepoFile -RelativePath "docs/TRD.md" -Content $trdContent

# ---------------------------------------------------------------------------
# App/package placeholders + root workspace config
# ---------------------------------------------------------------------------
Write-Section "Writing app/package placeholders"

$rootPackageJson = @'
{
  "name": "campus-companion",
  "private": true,
  "version": "0.1.0",
  "description": "Student-built, student-owned super app for campus life.",
  "workspaces": [
    "apps/*",
    "packages/*"
  ],
  "scripts": {
    "dev": "echo \"TODO: wire up dev script, e.g. npm run dev --workspace=apps/web\"",
    "build": "echo \"TODO: wire up build across workspaces\"",
    "lint": "echo \"TODO: wire up lint across workspaces\""
  },
  "license": "SEE LICENSE IN LICENSE"
}
'@
New-RepoFile -RelativePath "package.json" -Content $rootPackageJson

$webPackageJson = @'
{
  "name": "@campus-companion/web",
  "private": true,
  "version": "0.1.0",
  "description": "React + Tailwind frontend for Campus Companion.",
  "scripts": {
    "dev": "echo \"TODO: vite dev / next dev, once the app is scaffolded\"",
    "build": "echo \"TODO: build command\""
  },
  "license": "SEE LICENSE IN LICENSE"
}
'@
New-RepoFile -RelativePath "apps/web/package.json" -Content $webPackageJson

$webReadme = @'
# apps/web

React + Tailwind CSS frontend. Not yet scaffolded with a build tool
(Vite/Next.js)  -  this is a placeholder workspace.

Planned structure once scaffolded:

```
src/
|-- features/
|   |-- goods-marketplace/
|   |-- services/
|   |-- events/
|   |-- attendance/
|   |-- exams/
|   |-- interest-circles/
|   `-- creators/
|-- shared/         (uses @campus-companion/shared)
`-- app/            (routing, layout, providers)
```
'@
New-RepoFile -RelativePath "apps/web/README.md" -Content $webReadme

$functionsPackageJson = @'
{
  "name": "@campus-companion/functions",
  "private": true,
  "version": "0.1.0",
  "description": "Serverless API layer (Netlify Functions / Cloudflare Workers).",
  "scripts": {
    "dev": "echo \"TODO: netlify dev or wrangler dev\"",
    "build": "echo \"TODO: build command\""
  },
  "license": "SEE LICENSE IN LICENSE"
}
'@
New-RepoFile -RelativePath "apps/functions/package.json" -Content $functionsPackageJson

$functionsReadme = @'
# apps/functions

Serverless API layer sitting between the frontend and data stores. Target:
Netlify Functions or Cloudflare Workers (see docs/TRD.md for the tradeoff).

Not yet scaffolded  -  placeholder workspace.
'@
New-RepoFile -RelativePath "apps/functions/README.md" -Content $functionsReadme

$sharedPackageJson = @'
{
  "name": "@campus-companion/shared",
  "private": true,
  "version": "0.1.0",
  "description": "Shared types, constants, and schema definitions used by web + functions.",
  "license": "SEE LICENSE IN LICENSE"
}
'@
New-RepoFile -RelativePath "packages/shared/package.json" -Content $sharedPackageJson

$sharedReadme = @'
# packages/shared

Shared TypeScript types, enum definitions, and constants that mirror
`docs/database-schema.dbml`, so the frontend and functions stay in sync
with the schema without duplicating definitions.

Not yet implemented  -  placeholder workspace.
'@
New-RepoFile -RelativePath "packages/shared/README.md" -Content $sharedReadme

# ---------------------------------------------------------------------------
# Git init + first commit (no push)
# ---------------------------------------------------------------------------
if (-not $SkipGit) {
    Write-Section "Staging and committing scaffolded files"

    Push-Location $Root
    try {
        $gitAvailable = Get-Command git -ErrorAction SilentlyContinue
        if (-not $gitAvailable) {
            Write-Warning "git was not found on PATH  -  skipping add/commit."
        } elseif (-not (Test-Path (Join-Path $Root ".git"))) {
            Write-Warning "No .git folder here  -  skipping add/commit. Run this from your repo root, or 'git init' first."
        } else {
            git add -A | Out-Null
            $status = git status --porcelain
            if ($status) {
                git commit -m "chore: initial repo scaffold" | Out-Null
                Write-Host "  created initial commit"
            } else {
                Write-Host "  nothing to commit (already committed?)"
            }

            if ($RemoteUrl -ne "") {
                $existingRemote = git remote 2>$null
                if ($existingRemote -notcontains "origin") {
                    git remote add origin $RemoteUrl
                    Write-Host "  added remote 'origin' -> $RemoteUrl"
                } else {
                    Write-Host "  remote 'origin' already exists, leaving it as-is"
                }
            }
        }
    }
    finally {
        Pop-Location
    }
}

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
Write-Section "Done"
Write-Host ""
Write-Host "Repo scaffolded at: $Root" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Review LICENSE  -  it's a custom source-available, non-commercial,"
Write-Host "     no-redistribution license. Swap it out if you'd rather use a"
Write-Host "     published one (e.g. PolyForm Noncommercial)."
Write-Host "  2. Replace 'OWNER' / 'OWNER/REPO' placeholders in:"
Write-Host "       .github/CODEOWNERS"
Write-Host "       .github/ISSUE_TEMPLATE/config.yml"
Write-Host "  3. If this repo has no remote yet, create the empty repo on GitHub"
Write-Host "     (do NOT initialize it with a README/license there  -  you already"
Write-Host "     have those locally now)."
if ($RemoteUrl -eq "") {
    Write-Host "  4. Add the remote (if needed) and push:"
    Write-Host "       git remote add origin https://github.com/<you>/<repo>.git"
    Write-Host "       git push -u origin main"
} else {
    Write-Host "  4. Push:"
    Write-Host "       git push -u origin main"
}
Write-Host "  5. On GitHub: enable Discussions (Settings > Features), add"
Write-Host "     branch protection on 'main' (Settings > Branches), and add"
Write-Host "     repo topics/description for discoverability."
Write-Host ""
