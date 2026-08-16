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