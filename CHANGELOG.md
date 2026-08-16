# Changelog

All notable changes to this project are documented here.
Format loosely follows [Keep a Changelog](https://keepachangelog.com/).

---

## [0.2.0] — 2026-08-16

### Added — Database Schema v5 (`docs/database-schema.dbml`)

A comprehensive, DB-agnostic DBML schema covering the full Campus Companion super-app.
Designed for import into drawdb.app and compatible with PostgreSQL, MySQL, and SQLite/libSQL (Turso).

#### Core Design Decisions
- All IDs use `varchar` (UUID / auth-provider UID) — no engine-specific auto-increment.
- Soft-delete (`deleted_at`) on every table.
- `campus_id` baked into all tenant-level tables for future multi-campus support.
- Category/tag vocabulary uses lookup tables (not free-text or enums) — editable at runtime without a redeploy.
- `trust_score_events` audit log backs `users.trust_score`; `life_point_events` backs `users.life_points`.
- Goods Marketplace is **goods-only** (physical items). All service/gig/internship content lives in the separate Services module, which can even be deployed on a different DB service.
- `attendance_marks` keyed on `(schedule_slot_id, class_date)` to allow multiple sessions (e.g. lecture + lab) of the same subject per day.
- Recurring events use a parent `event_series` + materialized instance rows in `events`.

#### Enums (27 total)
`goods_listing_kind`, `goods_listing_mode`, `goods_listing_status`, `item_condition`,
`price_type_enum`, `quantity_unit_enum`, `interest_thread_status`, `report_entity_type`,
`report_status`, `event_organizer_type`, `event_status`, `rsvp_status`, `attendance_status`,
`exam_type`, `exam_entry_status`, `exam_confirmation_type`, `group_status`,
`join_request_status`, `swipe_direction`, `match_status`, `service_poster_type`,
`compensation_type_enum`, `duration_type_enum`, `application_method_enum`,
`service_listing_status`, `service_application_status`, `notification_type`

#### Tables Added by Module

**Tenancy & Lookups**
- `campuses` — multi-tenant root; email-domain allowlist for sign-up.
- `goods_categories`, `event_categories`, `creator_categories` — moderator-editable runtime taxonomy.

**Identity**
- `users` — `trust_score`, `life_points`, `branch_id` FK, `is_suspended`, `terms_accepted_at`, soft-delete, indexes on email/campus/branch.
- `clubs` / `club_admins` — club management with multi-admin support and role field.
- `roles` / `user_roles` — extensible RBAC with optional `campus_id` scope and `module_scope` per grant.
- `trust_score_events` — immutable audit trail for trust score deltas.
- `life_point_rules` — campus-configurable gamification rules (`is_active`, `module_scope`).
- `life_point_events` — audit trail for life-point deltas (automated + manual grants via `granted_by`).
- `user_blocks` — sitewide block list, independent of moderation reports; soft-delete on unblock.

**Goods Marketplace**
- `goods_listings` — offer/request × sale/rent/giveaway/buy; price type, quantity unit, condition, expires_at.
- `goods_listing_photos` — ordered photo attachments (cascade delete).
- `goods_listing_interests` — interest threads with `contact_revealed`; app-layer cascade-decline on listing close.

**Services & Gigs**
- `service_categories` / `service_skills` — taxonomy for internships, freelance, tutoring, tasks, etc.
- `organizations` — employer/org profiles with verification badge; `verified_by` audit trail.
- `organization_admins` — multi-admin org management with turnover support.
- `service_listings` — user/club/org poster types; compensation ranges, duration type, remote flag, rolling or fixed-deadline applications.
- `service_listing_skills` — required skills junction table.
- `service_applications` — full applicant pipeline (applied → shortlisted → interviewed → offered → accepted/rejected/withdrawn).
- `service_application_events` — status-change audit trail per application.

**Shared Moderation**
- `reports` — polymorphic report table covering 8 entity types; `resolution_notes`, `resolved_by`.

**Events**
- `event_series` — recurring event parent with RRULE-style recurrence rule and default time/location.
- `events` — materialized occurrence rows; supports one-off and series instances; `cover_image_url`, `capacity`.
- `event_rsvps` — going/interested/waitlisted/cancelled RSVP per user.

**Attendance** *(private per-student)*
- `subjects` — per-student subject list with `required_percentage` and optional term link.
- `class_schedule_slots` — weekly recurring slot (day_of_week + time range).
- `attendance_marks` — composite unique key `(schedule_slot_id, class_date)`; supports ad-hoc classes.

**Academic Terms**
- `academic_terms` — moderator-managed per campus; `is_current` flag for active semester.

**Exams** *(crowd-sourced)*
- `branches` — academic branches (CSE, ECE, etc.) per campus with unique campus+name constraint.
- `exam_entries` — crowd-sourced exam schedule with `verification_count` and status workflow.
- `exam_confirmations` — per-user confirm/flag actions; unique per user+entry.
- `user_exam_subscriptions` — per-user branch+term subscription for exam notifications.

**Interest Circles**
- `interest_tags` / `user_interest_tags` — curated tag taxonomy; `is_curated` flag for moderation queue.
- `interest_groups` — niche groups with `screening_question`, current WhatsApp link, JSON link history audit, `member_count`.
- `group_tags` — tag↔group junction.
- `group_join_requests` — moderated join flow with optional `answer_text`; `decided_at` audit.
- `group_memberships` — confirmed member list.
- `discover_profiles` — opt-in discovery/matching profile with `is_opted_in` gate.
- `discover_swipes` — directional swipes (interested/pass); unique pair constraint.
- `discover_matches` — mutual match state with `unmatch_reason` + `ended_at` audit.

**Campus Creators Directory**
- `creator_profiles` — opt-in creator card with category, bio, `is_claimed` claim flow, `nominated_by`.
- `creator_links` — platform links (instagram, youtube, linkedin, website, other) per creator.

**Notifications**
- `notifications` — 13 typed notification variants; polymorphic entity ref; `is_read` flag; indexed on (user_id, is_read).

#### drawdb Table Groups (11)
`tenancy_and_lookups`, `identity`, `goods_marketplace`, `services_module`, `moderation`,
`events_module`, `attendance_module`, `exams_module`, `interest_circles`, `creators_module`,
`notifications_module`

---

## [0.1.0] — 2026-08-16

### Added
- Initial repo scaffold: monorepo structure, docs, GitHub community files,
  and CI workflow placeholders.