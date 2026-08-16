# Product Requirements Document — Campus Companion

**Status:** Draft — living document  
**Last updated:** 2026-08-16

---

## Overview

Campus Companion is a student-built, student-owned super app for campus life. It is designed to run entirely independent of university IT, SSO, or administrative buy-in — any campus can onboard just by registering a domain. The app brings together seven distinct but complementary modules under one identity layer:

1. **Goods Marketplace** — buy, sell, rent, and give away physical items between students.
2. **Services & Gigs** — post and apply for internships, part-time jobs, freelance gigs, tutoring, tasks, and other campus-adjacent opportunities.
3. **Events** — discover, RSVP to, and organise campus events, including recurring series.
4. **Attendance** — private, per-student attendance tracker with configurable required-percentage alerts.
5. **Exams** — crowd-sourced exam schedule with peer verification.
6. **Interest Circles** — niche interest groups with a moderated join flow, and an opt-in peer-discovery feature.
7. **Campus Creators** — a directory of notable student creators, entrepreneurs, researchers, and athletes.

The initial target is a single campus of roughly 1,000–5,000 registered users, running on free-tier infrastructure.

---

## Who it's for

**Primary users** are undergraduate and postgraduate students at the target campus. All features are gated behind a college-email domain check at sign-up (Firebase Auth allowlist per campus). Students own their data and their presence in the app.

**Secondary actors** include:
- **Club representatives** — can organise events and post service listings on behalf of their club.
- **Organisation contacts** — external companies, labs, or NGOs registered on the platform who post service listings and manage their own hiring pipeline.
- **Moderators / term managers** — students or trusted users granted scoped roles to manage content, resolve reports, and maintain campus-level configuration (academic terms, life-point rules, etc.).

There is no university-admin login. The platform is deliberately outside institutional IT.

---

## Multi-campus & tenancy

The schema is built multi-tenant from day one (`campus_id` on every tenant-level table), but the initial rollout is single-campus. A campus is identified by its email domain; `campuses.email_domain` is the allowlist key used at sign-up.

All user-facing content — listings, events, groups, exam entries, attendance — is scoped to a campus. Cross-campus data sharing is out of scope.

---

## Identity & trust

### Accounts
- Sign up with a college email address only; domain is validated against the campus allowlist.
- Profile fields: display name, photo, roll number, branch (FK into the `branches` lookup), phone, Instagram handle, and a short bio.
- Accounts support soft-delete (`deleted_at`) so that listing/event history remains coherent after a user leaves.

### Trust score
Every account carries a `trust_score` (cached integer). It moves up and down based on explicit events logged in `trust_score_events` — e.g. completing a goods deal raises it; a upheld report lowers it. The score is visible to other users and acts as a lightweight reputation signal for marketplace transactions.

### Life Points
`life_points` is a separate gamification balance, deliberately distinct from trust score. It is earned by completing in-app actions (selling an item, attending an event, maintaining an attendance streak, getting hired through the platform, etc.) according to configurable rules in `life_point_rules`. A super-admin or campus moderator with the right role grant can configure rules per campus without a code deploy. Redemption mechanics are out of scope for v1 but the audit log (`life_point_events`) is in place.

### RBAC
Roles are defined in a `roles` table (extensible by inserting rows, not by changing code). Grants in `user_roles` can be scoped to a specific campus and/or a specific module (`goods_marketplace`, `services_module`, `events_module`, `exams_module`, `interest_circles`, `creators_module`). A null scope means platform-wide. A student can be an Interest Circles moderator without being a general moderator. Enforcement happens at the API layer.

Roles expected in the seed set (subject to finalisation in the TRD):
- `super_admin` — platform-wide, all campuses
- `moderator` — scoped per campus / per module
- `term_manager` — manages `academic_terms` for a campus
- `org_verifier` — can grant the verified badge to organisations
- `creator_curator` — can nominate and manage creator profiles

### User blocks
Any user can block another (stored in `user_blocks`). Blocked users' content is hidden from each other across all modules. This is a sitewide block, not a per-feature mute.

---

## Module: Goods Marketplace

The marketplace is **physical goods only** — textbooks, electronics, furniture, stationery, sports gear, clothing, and the like. Service-shaped work (tutoring, gigs, tasks) is intentionally out of scope here and lives in the Services module.

### Listing types
A listing has two orthogonal axes:
- **Kind:** `offer` (the poster has the item) or `request` (the poster wants the item).
- **Mode:** `sale`, `rent`, `giveaway`, or `buy`.

This covers the main real-world flows: "I'm selling my calculator," "I'm renting out my camera," "I need a second-hand lab coat," "I'm giving away old notes."

### Listing fields
Category (from `goods_categories`), title, description, price + price type (per-each, per-kg, per-hour, per-day, per-month, per-semester, or total), quantity, condition, meeting location, photos (ordered, up to N), and an optional expiry date.

### Interest threads
Interested students send a message to the poster through a `goods_listing_interests` thread. Statuses: `pending` → `accepted` → `contact_revealed` (or `declined`). Contact details (phone, Instagram) are only surfaced after the poster explicitly accepts. `accepted` is soft/informational — the listing isn't closed just because two people are talking. The hard close is when the poster marks the listing `sold` or `fulfilled`, which auto-declines all other pending threads at the app layer.

### Moderation
Listings can be reported via the shared `reports` table. Moderators resolve reports via a status workflow (`open` → `processed` / `dismissed`).

---

## Module: Services & Gigs

Where the Goods Marketplace is peer-to-peer, the Services module adds a real employer identity layer (`organizations`) and a real hiring pipeline. Poster types are: an individual student (`user`), a campus club (`club`), or a registered organisation (`organization`).

### Listing types
Driven by `service_categories`: Internship, Part-time Job, Freelance Gig, Tutoring, Task/Errand, Research Assistant, Volunteer, Creative/Design, Tech/Dev, Event Help, Other.

### Key listing fields
Compensation type (unpaid, stipend, hourly, fixed, revenue share, negotiable), compensation range, duration type (one-time, short-term, ongoing, fixed-term), remote flag, location, application deadline (null = rolling), required skills (from the `service_skills` table), application method (in-app or external link).

### Application pipeline
In-app applications move through: `applied` → `shortlisted` → `interviewed` → `offered` → `accepted` / `rejected` / `withdrawn`. Every status change is logged in `service_application_events` with a note and the identity of whoever made the move. This gives both poster and applicant a clear audit trail.

Closing a listing (`filled`, `closed`) does **not** auto-reject mid-pipeline applicants — the poster still needs to make explicit decisions per applicant, since people already shortlisted or interviewed shouldn't be silently dropped.

### Organisations
Any student can register an org profile. Verification (the `is_verified` badge) is granted by a user with the `org_verifier` role and is recorded with `verified_by`. Multiple students can be org admins (`organization_admins`) to handle membership turnover.

---

## Module: Events

Events can be one-off or part of a recurring series. Organisers can be individual users or clubs.

### Recurring events
A `event_series` row holds the recurrence rule (RRULE-style string) and defaults (location, time). Individual occurrences are materialised as real `events` rows — generated ahead of time (e.g. the next N weeks) by an app cron — so each instance can be independently RSVP'd to, modified, or cancelled without touching the others.

### RSVP
Status options: `going`, `interested`, `waitlisted`, `cancelled`. Capacity is an optional integer on the event; waitlisting logic is app-layer.

### Notifications
Reminders and update notifications (`event_reminder`, `event_update`) are dispatched via the shared notifications table.

---

## Module: Attendance

This module is strictly private per-student. No one else sees a student's attendance data.

### Structure
Students add their own **subjects** (optionally linked to the current academic term). Each subject has a `required_percentage` (default 75%). Subjects have a weekly schedule (`class_schedule_slots`). Actual class-level marks are in `attendance_marks`, keyed on `(schedule_slot_id, class_date)` — this key allows multiple sessions of the same subject in one day (lecture + lab) to be recorded independently. Ad-hoc / extra classes that aren't on the fixed schedule use a null `schedule_slot_id`.

Attendance percentage is computed at the app layer from these rows; there is no derived column in the DB.

### Notifications
A low-attendance warning (`attendance_low_warning`) and a general nudge (`attendance_nudge`) are available as notification types.

---

## Module: Academic Terms

Academic terms are moderator-managed (not hardcoded), since term dates shift every year and vary campus to campus. A `term_manager`-scoped role controls creation and the `is_current` toggle. The current term is the one where `is_current = true` and today falls within `[start_date, end_date]`.

Academic terms are used by: Attendance (to scope subjects to a semester), Exams (to namespace exam entries), and optionally Service listings (duration context).

---

## Module: Exams

The exam schedule is crowd-sourced — students add entries, and peers confirm or flag them.

### Flow
A student adds an `exam_entry` (branch, term, subject name, exam type, date, time). It starts as `unverified`. As other students confirm it (via `exam_confirmations`), `verification_count` increments and the status can be promoted to `verified` by the app layer. A flagged entry is reviewed by a moderator.

Students subscribe to a branch+term combination via `user_exam_subscriptions` to receive `exam_entry_confirmed` notifications.

### Exam types
`quiz`, `mid_sem`, `end_sem`, `other`.

### Branches
Branch names (CSE, ECE, Mechanical, etc.) are campus-scoped lookup rows, not free text or enums.

---

## Module: Interest Circles

Two distinct features live here under one module umbrella:

### Interest Groups
Niche communities (e.g. "Competitive Programming," "Film Club Overflow," "DSLR Lenders"). Groups can be public or require a moderated join (screening question + `group_join_requests` with `answer_text`). Approved members get access to the group's WhatsApp link (never exposed publicly). The link can be rotated; past links are kept in a JSON audit field on the group row for traceability without a separate table.

Groups have tags (from the shared `interest_tags` taxonomy). Moderators manage the curated tag set; users can suggest new tags (flagged with `is_curated = false` until approved).

### Discover (opt-in peer matching)
A separate opt-in feature (`discover_profiles.is_opted_in`). Students who opt in appear in a swipe-based discovery feed seeded by shared interest tags. Mutual `interested` swipes create a `discover_match`; either user can unmatch. The unmatch reason is logged for safety. This is strictly optional and fully isolated from the group feature.

---

## Module: Campus Creators Directory

A curated directory of notable student creators, entrepreneurs, athletes, researchers, and artists. Profiles are nominated (by another user, via `nominated_by`) and then claimed by the subject student (`is_claimed`). An unclaimed profile is not shown publicly. Once claimed, the student can add their own bio, category, and platform links (Instagram, YouTube, LinkedIn, website, other). The directory is browsable by category.

---

## Shared: Moderation

A single `reports` table handles flagging across all eight reportable entity types: `goods_listing`, `service_listing`, `organization`, `interest_group`, `event`, `exam_entry`, `creator_profile`, `user`. The report includes a `reason` key and optional `description`. Moderators with the appropriate role grant move reports through `open` → `processed` / `dismissed` and can leave resolution notes.

---

## Shared: Notifications

All in-app notifications are rows in the `notifications` table. Types cover every user-facing event across modules:

| Notification type | Trigger |
|---|---|
| `goods_listing_interest` | Someone sends an interest thread on your listing |
| `goods_listing_status_nudge` | Reminder to mark your listing sold/fulfilled |
| `service_application_status_changed` | Applicant or poster updates the pipeline status |
| `service_listing_deadline_reminder` | Deadline approaching for a listing you applied to |
| `event_reminder` | Upcoming event you RSVP'd to |
| `event_update` | An event you RSVP'd to was modified or cancelled |
| `attendance_nudge` | General attendance reminder |
| `attendance_low_warning` | Attendance dropped below required threshold |
| `exam_entry_confirmed` | An exam entry you subscribed to reached verified status |
| `group_join_approved` / `declined` | Your group join request was decided |
| `discover_match` | You got a mutual interest match in Discover |
| `report_resolved` | A report you filed was resolved |

Notifications are polymorphic-referenced (`related_entity_type`, `related_entity_id`) and marked read via `is_read`. Push delivery (FCM, etc.) is out of scope for v1; the table design supports it as an extension.

---

## Access control summary

| Actor | What they can do |
|---|---|
| Any authenticated student | Browse and create content in all modules within their campus |
| Club admin | Post events and service listings on behalf of the club |
| Org admin | Post service listings and manage applicants on behalf of the org |
| Moderator (campus-scoped) | Resolve reports, manage content within their module scope |
| Term manager | Create and toggle academic terms for their campus |
| Org verifier | Grant the verified badge to org profiles |
| Creator curator | Nominate and manage creator profiles |
| Super admin | All of the above across all campuses |

---

## Out of scope (v1)

- Direct messaging / chat between users (contact is exchanged out-of-band via phone/Instagram after a goods interest is accepted).
- University SSO or institutional login.
- Payment processing (all transactions are arranged offline).
- Push notifications (in-app notification feed only).
- Life Points redemption mechanics.
- Cross-campus discovery or listings.
- Mobile native apps (web-first, mobile-responsive).

---

## Open questions

- [ ] Life Points redemption — what can points be spent on? (v2 planning item)
- [ ] Discover feed algorithm — pure tag-overlap, or weighted by trust score / activity?
- [ ] Waitlist mechanics for events — FIFO automatic promotion, or manual by organiser?
- [ ] Should `creator_profiles` require a minimum trust score before a nomination goes through?
- [ ] Notification delivery — FCM integration timeline and token storage design.
- [ ] Finalize the seed set of `roles.key` values (see also TRD open items).