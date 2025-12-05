# SIMPLE_WEB HTTP Library Roadmap

---

## Claude: Start Here

**When starting a new conversation, read this file first.**

### Session Startup

1. **Read Eiffel reference docs**: `D:/prod/reference_docs/eiffel/claude/CONTEXT.md`
2. **Review this roadmap** for project-specific context
3. **Ask**: "What would you like to work on this session?"

### Key Reference Files

| File | Purpose |
|------|---------|
| `D:/prod/reference_docs/eiffel/claude/CONTEXT.md` | Generic Eiffel knowledge |
| `D:/prod/reference_docs/eiffel/language/gotchas.md` | Generic Eiffel gotchas |
| `D:/prod/reference_docs/eiffel/claude/HATS.md` | Focused work modes |
| `D:/prod/reference_docs/eiffel/language/patterns.md` | Verified code patterns (includes WSF server patterns) |

### Build & Test Commands

```batch
:: Compile (with environment variables)
FRAMEWORK="D:/prod/framework" SIMPLE_JSON="D:/prod/simple_json" TESTING_EXT="D:/prod/testing_ext" ^
  "C:\Program Files\Eiffel Software\EiffelStudio 25.02 Standard\studio\spec\win64\bin\ec.exe" ^
  -batch -config "D:\prod\simple_web\simple_web.ecf" -target simple_web_tests -c_compile -freeze

:: Clean compile
ec.exe -batch -config "D:\prod\simple_web\simple_web.ecf" -target simple_web_tests -c_compile -freeze -clean

:: Run tests
ec.exe -batch -config "D:\prod\simple_web\simple_web.ecf" -target simple_web_tests -tests
```

### Current Status

**Stable / Production-Ready** - 70 tests passing

Primary work now:
- Contract strengthening (Contracting Hat)
- Test coverage improvements (Testing Hat)
- Bug fixes as discovered

---

## Project Overview

SIMPLE_WEB is a high-level HTTP library for Eiffel providing both **client** and **server** capabilities. It wraps EiffelStudio's curl_http_client and EWF/WSF framework with a clean, developer-friendly API.

### Design Philosophy

- **Simple API**: Hide EWF/WSF complexity behind intuitive interfaces
- **Express-style routing**: Agent-based route handlers like `server.on_get("/path", agent handler)`
- **Fluent builders**: Chainable request construction
- **AI-ready**: Built-in clients for Claude, OpenAI, and Ollama

---

## Current State

**HTTP Client + Server Complete.** The library includes:

### Client Layer
- **SIMPLE_WEB_CLIENT**: Primary HTTP client using libcurl (GET, POST, PUT, DELETE)
- **SIMPLE_WEB_HYBRID_CLIENT**: Workaround for curl_http_client localhost bug (routes POST/PUT through curl.exe)

### Server Layer (NEW - December 2025)
- **SIMPLE_WEB_SERVER**: Main server with agent-based routing API
- **SIMPLE_WEB_SERVER_EXECUTION**: WSF_EXECUTION subclass for request dispatch
- **SIMPLE_WEB_SERVER_REQUEST**: Request wrapper (path params, query params, body, headers)
- **SIMPLE_WEB_SERVER_RESPONSE**: Response wrapper (send_json, send_text, status codes)
- **SIMPLE_WEB_SERVER_ROUTE**: URL pattern matching with `{param}` placeholders
- **SIMPLE_WEB_SERVER_ROUTER**: Singleton router (once function pattern)

### AI Clients
- **SIMPLE_WEB_CLAUDE_CLIENT**: Anthropic Claude API
- **SIMPLE_WEB_OPENAI_CLIENT**: OpenAI ChatGPT API
- **SIMPLE_WEB_OLLAMA_CLIENT**: Local Ollama server (generate, chat, list_models)

### Core
- **SIMPLE_WEB_REQUEST**: Fluent request builder
- **SIMPLE_WEB_RESPONSE**: Response wrapper (status, headers, body)
- **SIMPLE_WEB_CONSTANTS**: HTTP methods, status codes, AI endpoints

**70 tests (100% passing). Production-ready.**

---

## Class Structure

```
SIMPLE_WEB_CLIENT (HTTP client via libcurl)
+-- SIMPLE_WEB_HYBRID_CLIENT (localhost workaround)

SIMPLE_WEB_SERVER (HTTP server, inherits WSF_DEFAULT_SERVICE)
+-- SIMPLE_WEB_SERVER_EXECUTION (request dispatcher)
+-- SIMPLE_WEB_SERVER_REQUEST (request wrapper)
+-- SIMPLE_WEB_SERVER_RESPONSE (response wrapper)
+-- SIMPLE_WEB_SERVER_ROUTE (URL pattern matching)
+-- SIMPLE_WEB_SERVER_ROUTER (singleton route storage)

SIMPLE_WEB_CLAUDE_CLIENT (Anthropic API)
SIMPLE_WEB_OPENAI_CLIENT (OpenAI API)
SIMPLE_WEB_OLLAMA_CLIENT (Local Ollama)

SIMPLE_WEB_REQUEST (fluent request builder)
SIMPLE_WEB_RESPONSE (response container)
SIMPLE_WEB_CONSTANTS (HTTP constants)
```

---

## Dependencies

### Required Libraries (from ECF)
- `base` - Eiffel standard library
- `curl_http_client` - EiffelStudio network (libcurl wrapper)
- `http_network`, `http_authorization` - EiffelStudio HTTP support
- `wsf`, `httpd`, `default_standalone` - EWF framework (server)
- `encoder` - Text encoding
- `uri`, `uri_launcher`, `uri_template` - URL handling
- `jwt`, `jwt_openssl_ext` - JWT authentication
- `oauth_module` - OAuth support

### Required Environment Variables
```powershell
[System.Environment]::SetEnvironmentVariable('SIMPLE_JSON', 'D:\prod\simple_json', 'User')
[System.Environment]::SetEnvironmentVariable('TESTING_EXT', 'D:\prod\testing_ext', 'User')
[System.Environment]::SetEnvironmentVariable('SIMPLE_PROCESS', 'D:\prod\simple_process', 'User')
[System.Environment]::SetEnvironmentVariable('SIMPLE_SQL', 'D:\prod\simple_sql', 'User')
```

### Custom Libraries
- `simple_json` - JSON parsing/generation
- `simple_process` - Process execution helper (lightweight, replaces framework's FW_PROCESS_HELPER)
- `testing_ext` - TEST_SET_BASE for tests
- `simple_sql` - Database access (for WMS mock)

---

## Known Issues

### curl_http_client Localhost Bug
POST/PUT requests to `localhost` or `127.0.0.1` fail silently with the standard curl_http_client.

**Workaround**: Use `SIMPLE_WEB_HYBRID_CLIENT` which routes POST/PUT through `curl.exe` subprocess while keeping GET through libcurl.

---

## Path to World-Class

Following the simple_sql playbook: **Mock-Driven Development** - build realistic consumer applications to expose friction and drive API improvements.

### The Process

```
1. Choose a domain that heavily exercises HTTP client/server
2. Build a realistic application using SIMPLE_WEB
3. Note friction points (boilerplate, awkward patterns, missing features)
4. Add convenience methods to eliminate friction
5. Add tests for new API features
6. Verify mock app code simplifies
7. Repeat with next domain
```

### World-Class HTTP Library Standards

What developers expect from modern HTTP libraries (requests, axios, reqwest):

#### Client Side - Gaps to Address

| Feature | Why It Matters | Status |
|---------|----------------|--------|
| **Automatic retries with backoff** | Networks fail; good clients recover gracefully | Backlog |
| **Request/Response interceptors** | Logging, auth token refresh, metrics | Backlog |
| **Timeout configuration** | Connect vs read vs total timeouts | Backlog |
| **Session management** | Cookies, persistent connections, auth state | Backlog |
| **Streaming responses** | Large downloads without memory explosion | Backlog |
| **Multipart/form-data** | File uploads are ubiquitous | Backlog |
| **Proxy support** | Corporate environments need this | Backlog |
| **Response caching** | ETags, Last-Modified, conditional requests | Backlog |

#### Server Side - Gaps to Address

| Feature | Why It Matters | Status |
|---------|----------------|--------|
| **Middleware pipeline** | Cross-cutting concerns (auth, logging, CORS, compression) | Backlog |
| **Error handling middleware** | Consistent error responses | Backlog |
| **Static file serving** | Basic web server functionality | Backlog |
| **Request validation** | Schema validation before handler runs | Backlog |
| **Route groups/prefixes** | `/api/v1/*` without repetition | Backlog |
| **CORS handling** | Every API needs this | Backlog |
| **Graceful shutdown** | Don't drop in-flight requests | Backlog |

#### Both Sides

| Feature | Why It Matters | Status |
|---------|----------------|--------|
| **Structured errors** | Not just strings - codes, context, causes | Backlog |
| **Comprehensive logging** | Debug without modifying code | Backlog |
| **Contract coverage** | DBC throughout | Ongoing |
| **Test coverage** | Edge cases, error paths | Ongoing |
| **HTML Documentation** | Docs with EIS integration | Backlog |

### Proposed Mock Applications

| Mock App | Would Exercise | Recommended |
|----------|----------------|-------------|
| **REST API Backend** | Server CRUD, JSON, error responses, connects simple_sql + simple_web | **Yes - First** |
| **API Gateway/Proxy** | Client forwarding, Server receiving, headers, auth passthrough | Future |
| **Webhook Receiver** | Server routes, request validation, async processing | Future |
| **Web Scraper** | Client retries, rate limiting, cookies, redirects | Future |
| **OAuth Client** | Auth flows, token refresh, session management | Future |

### Recommended First Mock: REST API Backend

A REST API that serves data from simple_sql would:
- Exercise server routing heavily
- Need middleware (auth, logging, error handling)
- Require JSON request/response patterns
- Connect the two libraries together
- Be a realistic, useful application

**Expected Friction Points to Discover:**
- JSON body parsing boilerplate
- Error response consistency
- Authentication patterns
- Request validation
- CORS handling
- Logging/debugging

---

## Proposed Architecture

### Phase 1 - Foundation (Current) ✅ COMPLETE

| Feature | Description | Status |
|---------|-------------|--------|
| **HTTP Client** | GET, POST, PUT, DELETE via libcurl | ✅ |
| **Fluent Request Builder** | Chainable request construction | ✅ |
| **HTTP Server** | Agent-based routing, Express-style API | ✅ |
| **Path Parameters** | URL pattern matching with `{param}` | ✅ |
| **Query Parameters** | Access to URL query string | ✅ |
| **JSON Response** | send_json, send_text helpers | ✅ |
| **AI Clients** | Claude, OpenAI, Ollama integration | ✅ |

### Phase 2 - Server Essentials (Mock-Driven)

To be driven by REST API Backend mock app. Expected features:

| Feature | Description | Status |
|---------|-------------|--------|
| **Middleware Pipeline** | Pre/post request processing | Planned |
| **Error Handling** | Structured errors, consistent responses | Planned |
| **CORS Support** | Cross-origin request handling | Planned |
| **Request Body Parsing** | JSON body to object helpers | Planned |
| **Route Groups** | Prefix groups for API versioning | Planned |
| **Logging Middleware** | Request/response logging | Planned |

### Phase 3 - Client Resilience (Mock-Driven)

To be driven by Web Scraper or API Gateway mock. Expected features:

| Feature | Description | Status |
|---------|-------------|--------|
| **Retry Logic** | Automatic retry with exponential backoff | Planned |
| **Timeout Config** | Granular timeout control | Planned |
| **Interceptors** | Request/response hooks | Planned |
| **Cookie Management** | Session persistence | Planned |

### Phase 4 - Advanced (Mock-Driven)

| Feature | Description | Status |
|---------|-------------|--------|
| **WebSocket Support** | Real-time communication | Planned |
| **Streaming** | Large response handling | Planned |
| **File Uploads** | Multipart form data | Planned |
| **OAuth Flows** | Authentication helpers | Planned |

---

## Potential Future Work (Backlog)

These are ideas not yet validated by mock apps:

| Feature | Description | Priority |
|---------|-------------|----------|
| **WebSocket Support** | Real-time bidirectional communication | Medium |
| **Response Caching** | Cache GET responses with TTL | Low |
| **Connection Pooling** | Reuse HTTP connections | Low |
| **Rate Limiting** | Client-side request throttling | Low |
| **HTTPS Certificate Pinning** | Enhanced security | Low |

---

## API Quick Reference

### HTTP Client
```eiffel
-- Simple GET
create client.make
response := client.get ("https://api.example.com/users")

-- Fluent builder
response := client.request
    .url ("https://api.example.com/users")
    .header ("Authorization", "Bearer token")
    .post ("{%"name%":%"John%"}")

-- Hybrid client for localhost
create hybrid.make
response := hybrid.post ("http://localhost:8080/api", body)
```

### HTTP Server
```eiffel
-- Create and configure server
create server.make (8080)

-- Register routes with agents
server.on_get ("/", agent handle_root)
server.on_get ("/api/users", agent handle_users)
server.on_get ("/api/users/{id}", agent handle_user)
server.on_post ("/api/users", agent create_user)

-- Start server
server.start

-- Handler example
handle_user (req: SIMPLE_WEB_SERVER_REQUEST; res: SIMPLE_WEB_SERVER_RESPONSE)
    local
        user_id: STRING_32
    do
        user_id := req.path_param ("id")
        res.send_json ("{%"id%":%"" + user_id + "%"}")
    end
```

### AI Clients
```eiffel
-- Ollama (local)
create ollama.make ("http://localhost:11434")
response := ollama.generate ("llama2", "What is Eiffel?")

-- Claude
create claude.make ("your-api-key")
response := claude.send_message ("What is Eiffel?")

-- OpenAI
create openai.make ("your-api-key")
response := openai.send_message ("What is Eiffel?")
```

---

## Session Notes

### 2025-12-02 (HTTP Server Implementation)

**Task**: Add HTTP server capability to simple_web

**Implementation**:
- Explored EWF (Eiffel Web Framework) architecture
- Designed Express.js-style agent-based routing API
- Created 6 server classes (850 LOC total)
- 14 new server tests (route matching, router functionality)

**Key Technical Learnings**:
- WSF architecture: `WSF_DEFAULT_SERVICE` + `WSF_EXECUTION` pattern
- Singleton via `once` functions for shared router between server and execution
- `WGI_INPUT_STREAM.read_string` is a procedure populating `last_string`
- `WSF_VALUE.string_representation` returns READABLE_STRING_32
- Use `to_string_8` not obsolete `as_string_8`

**ECF Fixes**:
- Converted hard-coded paths to environment variables
- Removed self-referencing library entry (bug)
- Added `wsf` library for core WSF classes

**Result**: 70/70 tests passing

### 2025-12-02 (WMS REST API Mock)

**Task**: Build WMS REST API mock application to exercise simple_web server/client

**Implementation**:
- Created `wms_api` and `wms_api_tests` targets in simple_web.ecf
- Built `WMS_API_SERVER` - REST API wrapping simple_sql's WMS_APP
- Built `WMS_WORKER_SIMULATOR` - Simulates warehouse worker with phone app
- 8 new tests for WMS API functionality

**Key Friction Points Discovered**:

#### Server-Side Friction [F1-F6]
| Code | Friction Point | Current State | Desired State |
|------|----------------|---------------|---------------|
| F1 | JSON body parsing | Manual parsing on each route | Automatic JSON body object on request |
| F2 | Error responses | Inconsistent string errors | Structured error response helper |
| F3 | Content-type handling | Manual header checks | Automatic JSON detection |
| F4 | Route path validation | No validation | Built-in parameter validation |
| F5 | Response building | Verbose JSON building | Fluent response builder |
| F6 | No middleware | Auth/logging repeated in each handler | Middleware pipeline |

#### Client-Side Friction [C1-C5]
| Code | Friction Point | Current State | Desired State |
|------|----------------|---------------|---------------|
| C1 | Localhost bug | Must use SIMPLE_WEB_HYBRID_CLIENT | Regular client that just works |
| C2 | JSON building | Manual string construction | Fluent JSON builder or auto-serialization |
| C3 | Error handling | `if response.status_code >= 400` | `response.is_error`, `response.error_message` |
| C4 | No retry logic | Manual retry loops | `client.with_retry(3).post(...)` |
| C5 | No request logging | Manual print before each request | Built-in request/response logging |

#### Library Infrastructure Friction
| Issue | Resolution |
|-------|------------|
| `framework` library brings in `process` lib which doesn't support SCOOP | Created `simple_process` library as lightweight replacement |
| `randomizer` library old/unnecessary | User noted this can be removed |
| ECF concurrency settings | Must use `support="thread" use="thread"` to match process library |

**New Library Created: simple_process**
- Location: `D:\prod\simple_process`
- Purpose: Lightweight process execution (replaces FW_PROCESS_HELPER)
- Key class: `SIMPLE_PROCESS_HELPER` - `output_of_command`, `has_file_in_path`
- 9 tests passing
- Concurrency: `support="thread" use="thread"` (matches ISE process library)

**ECF Changes**:
- simple_web now uses `simple_process` instead of `framework`
- simple_web concurrency changed to `support="thread" use="thread"`
- Added `wms_api` and `wms_api_tests` targets

**Result**: 8/8 WMS API tests passing

---

## Notes

- All development follows Eiffel Design by Contract principles
- Classes use ECMA-367 standard Eiffel
- Testing via EiffelStudio AutoTest framework with TEST_SET_BASE
- Server built on enterprise-grade EWF/WSF framework
