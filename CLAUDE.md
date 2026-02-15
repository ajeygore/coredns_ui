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

# Run dev server (starts Rails + Tailwind watcher)
foreman start -f Procfile.dev

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
- `DnsZone` — a DNS zone tied to a Redis host; has_many `DnsRecord`s. On create/update, syncs records to Redis.
- `DnsRecord` — individual record (A, AAAA, CNAME, TXT, MX, NS, PTR, SRV, SOA, etc.) belonging to a zone.
- `User` — Google OAuth user with optional admin flag. Access controlled by `ALLOWED_EMAIL_DOMAINS` and `WHITELISTED_EMAILS` env vars.
- `ApiToken` — bearer tokens for REST API access.

**Auth flow:**
- Web UI: Google OAuth2 via OmniAuth → `SessionsController#create` → session-based. `require_login` before_action on `ApplicationController`.
- API: Bearer token validated in `Api::V1::ZonesController` via `authenticate_api_token!`.

**Redis integration:** DNS records are written to Redis so CoreDNS (with its Redis plugin) can serve them. The `DnsZone` model handles syncing records to the zone's configured `redis_host`.

**Routes:** Web CRUD is nested (`dns_zones/:id/dns_records`). API lives under `api/v1/zones/` with action-specific endpoints (create_subdomain, add_a, add_mx, create_acme_challenge, etc.).

## Environment Variables

Copy `.env.example` to `.env`. Required:
- `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` — OAuth credentials
- `APP_PUBLIC_FQDN` — public hostname for the app
- `ALLOWED_EMAIL_DOMAINS` — comma-separated domains allowed to log in
- `WHITELISTED_EMAILS` — comma-separated individual emails allowed

## RuboCop Config

Documentation cops and `Style/FrozenStringLiteralComment` are disabled (`.rubocop.yml`). Uses `rubocop-discourse` and `rubocop-sensible` plugins.

## External Dependencies

Redis must be running for DNS record operations. Use `docker-compose up -d` to start Redis locally (configured in `docker-compose.yml`).
