# Contributing to Malady

Thanks for your interest in improving Malady! This document covers how to set up,
the standards we hold code to, and the contribution workflow.

## Licensing of contributions

Malady is licensed under the **AGPL-3.0**. By submitting a contribution you agree
that it is licensed under the same terms. Don't contribute code you don't have the
right to license this way.

## Development setup

See the [README](README.md#getting-started-development). In short:

```bash
bundle install
bin/rails db:prepare
bin/dev            # runs the server AND the Tailwind watcher
```

Use `bin/dev` (not `bin/rails server` alone) so Tailwind CSS is built — otherwise
styles will be missing.

## Workflow

1. **Open an issue first** for anything non-trivial, so the approach can be agreed
   before you invest time.
2. **Branch** off the default branch: `git checkout -b short-descriptive-name`.
3. **Write tests first (TDD).** Add a failing test, make it pass, then refactor.
4. **Keep changes focused.** One logical change per pull request.
5. **Open a pull request** describing the what and why, and linking the issue.

## Coding standards

- **Ruby/Rails:** follow [`rubocop-rails-omakase`](https://github.com/rails/rubocop-rails-omakase)
  (shipped with the app). Run `bin/rubocop` and fix offenses before pushing.
- **Tests:** Minitest only (no RSpec). Every model, service, controller, and
  integration path should be covered. Tests that sign a user in must use the
  `confirmed_user` helper (Devise `:confirmable` blocks unconfirmed logins).
- **Security:** all user-data queries must be **owner-scoped** (`current_user.metrics…`),
  never a bare `Metric.find`/`DataPoint.find`. The admin area is the only place that
  operates across users, and it is gated by `Admin::BaseController#require_admin`.
- **Privacy & time:** store timestamps in **UTC**; resolve to local time in the
  browser. Don't add at-rest data dumps or logging of metric values.
- **Views:** Haml + Tailwind utility classes, mobile-first, with `dark:` variants
  for dark mode. Prefer Hotwire (Turbo Streams / Stimulus) over bespoke JS.
- **i18n:** user-facing strings go through `t()` and `config/locales/en.yml`.

## Running the checks

```bash
bin/rails test          # unit / controller / integration
bin/rails test:system   # Capybara system tests (needs Chrome)
bin/rubocop             # style
bin/brakeman            # static security analysis
```

All of these should be green before you open a PR.

A **pre-commit hook** runs the fast checks (RuboCop, Brakeman, gem/importmap
audits, and the unit tests) so CI failures surface locally. It's enabled
automatically by `bin/setup`; to enable it manually run:

```bash
git config core.hooksPath .githooks
```

Bypass it for a work-in-progress commit with `git commit --no-verify`.

## Commit messages

Write clear, imperative-mood subjects ("Add CSV export", not "Added"/"Adds").
Explain the *why* in the body when it isn't obvious. Group related changes; avoid
mixing unrelated refactors into a feature commit.

## Project design docs

Design specs and the implementation plan live under
`docs/superpowers/`. If you're making a substantial change, skim the relevant spec
first and update it if your change alters the design.

## Reporting security issues

Please do **not** open a public issue for security vulnerabilities. Report them
privately to the maintainers so a fix can be prepared before disclosure.
