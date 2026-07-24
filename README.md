# AngelSwing Rails Coding Test API

A production-quality, JSON API built with **Ruby on Rails 7.1** (API-only mode) and **PostgreSQL**. Implements user authentication via JWT and a protected `Content` resource with owner-based authorization.

---

## Table of Contents

- [Tech Stack](#tech-stack)
- [Running with Docker (Recommended)](#running-with-docker-recommended)
- [Running without Docker](#running-without-docker)
- [Environment Variables](#environment-variables)
- [API Reference](#api-reference)
  - [POST /api/v1/users/signup](#post-apiv1userssignup)
  - [POST /api/v1/auth/signin](#post-apiv1authsignin)
  - [GET /api/v1/contents](#get-apiv1contents)
  - [GET /api/v1/contents/:id](#get-apiv1contentsid)
  - [POST /api/v1/contents](#post-apiv1contents)
  - [PUT /api/v1/contents/:id](#put-apiv1contentsid)
  - [DELETE /api/v1/contents/:id](#delete-apiv1contentsid)
- [HTTP Status Codes](#http-status-codes)
- [Running Tests](#running-tests)
- [Assumptions & Design Decisions](#assumptions--design-decisions)
- [Stretch Goals](#stretch-goals)
- [Deployment Notes](#deployment-notes)

---

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Ruby 3.3.6 |
| Framework | Rails 8.1.3 (API-only) |
| Database | PostgreSQL 16 |
| Authentication | JWT (`jwt` gem) + `has_secure_password` (`bcrypt`) |
| Containerization | Docker + Docker Compose |
| Tests | RSpec + FactoryBot + Shoulda::Matchers |

---

## Running with Docker (Recommended)

**Prerequisites:** Docker Desktop (or Docker Engine + Docker Compose v2) installed.

```bash
# 1. Clone the repo
git clone <repo-url>
cd rails

# 2. (Optional) Copy the env example and adjust if needed
cp .env.example .env

# 3. Start the full stack — builds, migrates, and starts the server
docker compose up --build
```

The API will be available at **`http://localhost:3000`**.

> **How it works:** The `web` service waits for the PostgreSQL `healthcheck` to pass (via `depends_on: condition: service_healthy`), then the entrypoint script runs `rails db:prepare` (creates the database if needed and runs all migrations) before starting Puma.

To run in the background:

```bash
docker compose up --build -d
```

To stop:

```bash
docker compose down
```

To destroy volumes (wipes the database):

```bash
docker compose down -v
```

---

## Running without Docker

**Prerequisites:** Ruby 3.2.2, Bundler, PostgreSQL running locally.

```bash
# 1. Install dependencies
bundle install

# 2. Configure environment
cp .env.example .env
# Edit .env to point DATABASE_URL at your local Postgres instance

# 3. Create and migrate the database
bin/rails db:prepare

# 4. Start the server
bin/rails server
```

The API will be available at **`http://localhost:3000`**.

---

## Environment Variables

Copy `.env.example` → `.env` and fill in values:

| Variable | Required | Description |
|---|---|---|
| `DATABASE_URL` | ✅ | PostgreSQL connection string. Format: `postgresql://user:pass@host:port/db` |
| `JWT_SECRET` | ✅ | Secret used to sign JWT tokens. Use `openssl rand -hex 64` in production. |
| `FORCE_SSL` | ❌ | Set to `true` to force HTTPS redirects in production. |
| `RAILS_MASTER_KEY` | ❌ | Required only if using Rails encrypted credentials. |

> ⚠️ **Never commit `.env` to version control.** It is included in `.gitignore`.

---

## API Reference

**Base URL:** `http://localhost:3000/api/v1`

All request bodies use **camelCase** keys. All response bodies use **camelCase** keys in a JSON:API-flavoured envelope.

---

### POST /api/v1/users/signup

Create a new user account and receive a JWT token.

**Request Body:**

```json
{
  "firstName": "John",
  "lastName": "Doe",
  "email": "john@email.com",
  "password": "complex_password",
  "country": "USA"
}
```

| Field | Required | Rules |
|---|---|---|
| `firstName` | ✅ | |
| `lastName` | ✅ | |
| `email` | ✅ | Must be valid format, unique (case-insensitive) |
| `password` | ✅ | Minimum 6 characters |
| `country` | ❌ | Optional |

**Success — `201 Created`:**

```json
{
  "data": {
    "id": 1,
    "type": "users",
    "attributes": {
      "token": "<jwt>",
      "email": "john@email.com",
      "name": "John Doe",
      "country": "USA",
      "createdAt": "2026-07-23T12:00:00.000Z",
      "updatedAt": "2026-07-23T12:00:00.000Z"
    }
  }
}
```

**Failure — `422 Unprocessable Entity`:**

```json
{ "errors": ["Email is invalid", "Password is too short (minimum is 6 characters)"] }
```

---

### POST /api/v1/auth/signin

Authenticate with email and password; receive a JWT token.

**Request Body** *(note: credentials are nested under `auth`)*:

```json
{ "auth": { "email": "john@email.com", "password": "complex_password" } }
```

**Success — `200 OK`:** Same envelope shape as sign-up.

**Failure — `401 Unauthorized`:**

```json
{ "error": "Invalid email or password" }
```

---

### GET /api/v1/contents

List all contents. Also accessible at `/api/v1/content` (alias).

> **Note on alias:** The spec's Postman collection references both `/contents` (plural) and `/content` (singular) for the list endpoint. Both routes are registered and map to the same `index` action. See [Assumptions](#assumptions--design-decisions) for details.

**Headers:** `Authorization: Bearer <token>`

**Success — `200 OK`:**

```json
{
  "data": [
    {
      "id": 1,
      "type": "content",
      "attributes": {
        "title": "Content A",
        "body": "The body text.",
        "createdAt": "2026-07-23T12:00:00.000Z",
        "updatedAt": "2026-07-23T12:00:00.000Z"
      }
    }
  ]
}
```

**Failure — `401 Unauthorized`:** `{ "error": "Unauthorized" }`

---

### GET /api/v1/contents/:id

Retrieve a single content by ID.

**Headers:** `Authorization: Bearer <token>`

**Success — `200 OK`:**

```json
{
  "data": {
    "id": 1,
    "type": "content",
    "attributes": {
      "title": "Content A",
      "body": "The body text.",
      "createdAt": "2026-07-23T12:00:00.000Z",
      "updatedAt": "2026-07-23T12:00:00.000Z"
    }
  }
}
```

**Failures:**
- `401` — No/invalid token: `{ "error": "Unauthorized" }`
- `404` — Not found: `{ "error": "Couldn't find Content with 'id'=99" }`

---

### POST /api/v1/contents

Create a new content item owned by the authenticated user.

**Headers:** `Authorization: Bearer <token>`, `Content-Type: application/json`

**Request Body:**

```json
{ "title": "Content A", "body": "This will be the actual long body for the content." }
```

Both `title` and `body` are required.

**Success — `201 Created`:**

```json
{
  "data": {
    "id": 1,
    "type": "content",
    "attributes": {
      "title": "Content A",
      "body": "This will be the actual long body for the content.",
      "createdAt": "2026-07-23T12:00:00.000Z",
      "updatedAt": "2026-07-23T12:00:00.000Z"
    }
  }
}
```

**Failures:**
- `401` — No/invalid token: `{ "error": "Unauthorized" }`
- `422` — Validation error: `{ "errors": ["Title can't be blank"] }`

---

### PUT /api/v1/contents/:id

Update an existing content item. **Only the owner can update.**

**Headers:** `Authorization: Bearer <token>`, `Content-Type: application/json`

**Request Body:**

```json
{ "title": "Updated Title", "body": "Updated body." }
```

**Success — `200 OK`:** Same envelope as create/show.

**Failures:**
- `401` — No/invalid token: `{ "error": "Unauthorized" }`
- `403` — Not the owner: `{ "error": "You are not authorized to modify this content" }`
- `404` — Not found: `{ "error": "Couldn't find Content with 'id'=99" }`
- `422` — Validation error: `{ "errors": ["Title can't be blank"] }`

---

### DELETE /api/v1/contents/:id

Delete a content item. **Only the owner can delete.**

**Headers:** `Authorization: Bearer <token>`

**Success — `200 OK`:**

```json
{ "message": "Deleted" }
```

**Failures:**
- `401` — No/invalid token: `{ "error": "Unauthorized" }`
- `403` — Not the owner: `{ "error": "You are not authorized to modify this content" }`
- `404` — Not found: `{ "error": "Couldn't find Content with 'id'=99" }`

---

## HTTP Status Codes

| Code | Meaning | When |
|---|---|---|
| `200` | OK | Successful GET, PUT, DELETE |
| `201` | Created | Successful POST (signup, create content) |
| `400` | Bad Request | Missing required parameters |
| `401` | Unauthorized | Missing/invalid/expired token; wrong credentials |
| `403` | Forbidden | Authenticated but not the resource owner |
| `404` | Not Found | Resource does not exist |
| `422` | Unprocessable Entity | Validation errors |

---

## Running Tests

```bash
# Ensure your test database is set up
DATABASE_URL=postgresql://postgres:password@localhost:5432/angelswing_api_test \
  RAILS_ENV=test bin/rails db:prepare

# Run all specs
bundle exec rspec

# Run only request specs
bundle exec rspec spec/requests/

# Run only model specs
bundle exec rspec spec/models/
```

The test suite covers:
- ✅ Content model validations and associations
- ✅ Successful create/update/delete on contents
- ✅ Validation failures (422)
- ✅ 403 not-owner case
- ✅ 401 no-token / invalid token
- ✅ 404 not-found
- ✅ camelCase response key verification
- ✅ `/content` alias route
- ✅ User signup with camelCase input
- ✅ Auth signin success and failure paths

