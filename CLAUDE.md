# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

CoreDNS UI — a Rails 8.0 web interface for managing CoreDNS zones and records via the Redis plugin. Provides both a web UI (Google OAuth) and a REST API (bearer token auth).

## Commands

```bash
# Install dependencies
bundle install

# Database setup
bin/rails db:create db:migrate db:seed

# Run dev server (starts Rails + Tailwind watcher via foreman)
foreman start -f Procfile.dev

# Start Redis (required for DNS record operations)
docker-compose up -d

# Tests
bundle exec rspec                              # full suite
bundle exec rspec spec/models/dns_zone_spec.rb # single file
bundle exec rspec spec/models/ -e "validates"  # by example name

# Linting
bundle exec rubocop
bundle exec rubocop -a                         # auto-correct

# Security scan
bundle exec brakeman
```

## Architecture

**Stack:** Ruby 3.3.4, Rails 8.0.2, SQLite3, Redis, Puma, Tailwind CSS, Slim templates, Stimulus.js, ImportMap

**Core domain models:**
- `DnsZone` — a DNS zone tied to a `redis_host`; has_many `DnsRecord`s. Handles syncing records to Redis via `refresh` (full resync) and `update_redis` (single record name update). Cannot be deleted while it has records.
- `DnsRecord` — individual DNS record belonging to a zone. Record types defined as constants (A, AAAA, CNAME, TXT, MX, NS, PTR, SRV, SOA, etc.). MX record data format is `"priority hostname"` (e.g., `"10 mail.example.com"`).
- `User` — Google OAuth user. First user to register automatically becomes admin.
- `ApiToken` — bearer tokens (40-char hex) for REST API access, belonging to a user.

**Auth flow:**
- Web UI: Google OAuth2 via OmniAuth → `SessionsController#create` → session-based. `require_login` before_action on `ApplicationController`. Access controlled by `ALLOWED_EMAIL_DOMAINS` and `WHITELISTED_EMAILS` env vars (checked in `SessionsController#email_allowed?`).
- API: `Api::ApiController` skips login/CSRF, authenticates via raw `Authorization` header matched against `ApiToken` records. `Api::V1::ZonesController` inherits from it.

**Redis data format:** Each zone is a Redis hash keyed by `"zonename."` (trailing dot). Hash fields are record names (e.g., `@`, `*`, `_acme-challenge`), values are JSON objects with keys like `a`, `ns`, `txt`, `mx`, `cname` containing arrays of record data.

**Routes:** Web CRUD is nested (`dns_zones/:id/dns_records`). API lives under `api/v1/zones/` with action-specific endpoints (`create_subdomain`, `add_a`, `add_mx`, `create_acme_challenge`, `delete_subdomain`, `delete_acme_challenge`, `delete_mx`). Zone refresh available at `GET /dns_zones/:id/refresh`.

## Environment Variables

Copy `.env.example` to `.env`. Key variables:
- `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` — OAuth credentials
- `APP_PUBLIC_FQDN` — public hostname for the app
- `ALLOWED_EMAIL_DOMAINS` — comma-separated domains allowed to log in
- `WHITELISTED_EMAILS` — comma-separated individual emails allowed
- `REDIS_HOST` — defaults to `localhost` if unset

## RuboCop Config

Documentation cops and `Style/FrozenStringLiteralComment` are disabled (`.rubocop.yml`). Uses `rubocop-discourse` and `rubocop-sensible` plugins.
