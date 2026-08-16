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