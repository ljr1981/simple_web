<p align="center">
  <img src="https://raw.githubusercontent.com/ljr1981/claude_eiffel_op_docs/main/artwork/LOGO.png" alt="simple_ library logo" width="400">
</p>

# SIMPLE_WEB

High-level HTTP library for Eiffel, providing clean APIs for both HTTP client operations and HTTP server development.

## Features

### HTTP Client
- **Fluent request builder** - chainable API for constructing HTTP requests
- **JSON support** - easy POST/PUT with JSON bodies
- **AI clients** - ready-to-use clients for Ollama, Claude, OpenAI, and Grok
- **Response handling** - structured access to status, headers, and body

### HTTP Server (NEW)
- **Agent-based routing** - register handlers with `on_get`, `on_post`, etc.
- **Path parameters** - pattern matching with `{id}` placeholders
- **Clean request/response API** - wrappers around WSF primitives
- **JSON support** - send JSON objects directly with `send_json_object`

## Installation

Add to your ECF:

```xml
<library name="simple_web" location="$SIMPLE_WEB/simple_web.ecf"/>
```

### Environment Variables

Set these environment variables for library references:
- `SIMPLE_WEB` - path to simple_web directory
- `SIMPLE_PROCESS` - path to simple_process library
- `SIMPLE_JSON` - path to simple_json library

### Dependencies

- EiffelStudio 25.02+
- `curl_http_client` library (included with EiffelStudio)
- `curl.exe` available on PATH (for hybrid client)
- `simple_process` library
- `simple_json` library
- EWF libraries (wsf, httpd, default_standalone - included with EiffelStudio)

## HTTP Client Usage

### Basic HTTP Operations

```eiffel
local
    l_client: SIMPLE_WEB_CLIENT
    l_response: SIMPLE_WEB_RESPONSE
do
    create l_client.make

    -- GET
    l_response := l_client.get ("https://api.example.com/data")

    -- POST JSON
    l_response := l_client.post_json ("https://api.example.com/data",
        "{%"name%":%"value%"}")

    if l_response.is_success then
        print (l_response.body)
    end
end
```

### Hybrid Client (Recommended for Localhost)

Use `SIMPLE_WEB_HYBRID_CLIENT` when communicating with localhost services like Ollama. It works around a known issue in the `curl_http_client` library that corrupts POST bodies to localhost.

```eiffel
local
    l_client: SIMPLE_WEB_HYBRID_CLIENT
    l_response: SIMPLE_WEB_RESPONSE
do
    create l_client.make

    -- Uses curl.exe process for POST (reliable)
    l_response := l_client.post_json ("http://localhost:11434/api/generate",
        "{%"model%":%"llama3%",%"prompt%":%"Hello%",%"stream%":false}")

    -- Uses libcurl for GET (fast)
    l_response := l_client.get ("http://localhost:11434/api/tags")
end
```

### Ollama Client

```eiffel
local
    l_ollama: SIMPLE_WEB_OLLAMA_CLIENT
    l_response: SIMPLE_WEB_RESPONSE
do
    create l_ollama

    -- Generate completion
    l_response := l_ollama.generate ("llama3", "Why is the sky blue?")

    -- Chat
    l_response := l_ollama.chat ("llama3",
        <<["user", "Hello"], ["assistant", "Hi!"], ["user", "How are you?"]>>)

    -- List models
    l_response := l_ollama.list_models
end
```

### Fluent Request Builder

```eiffel
local
    l_client: SIMPLE_WEB_CLIENT
    l_request: SIMPLE_WEB_REQUEST
    l_response: SIMPLE_WEB_RESPONSE
do
    create l_client.make

    create l_request.make_post ("https://api.example.com/data")
    l_request.with_bearer_token ("your-token")
            .with_json_body ("{%"key%":%"value%"}")
            .with_timeout (30000)
            .do_nothing

    l_response := l_client.execute (l_request)
end
```

## HTTP Server Usage

### Basic Server

```eiffel
local
    l_server: SIMPLE_WEB_SERVER
do
    create l_server.make (8080)

    -- Register routes
    l_server.on_get ("/", agent handle_root)
    l_server.on_get ("/api/users", agent handle_users)
    l_server.on_get ("/api/users/{id}", agent handle_user)
    l_server.on_post ("/api/users", agent create_user)
    l_server.on_put ("/api/users/{id}", agent update_user)
    l_server.on_delete ("/api/users/{id}", agent delete_user)

    -- Start server (blocking)
    l_server.start
end

feature {NONE} -- Handlers

handle_root (a_request: SIMPLE_WEB_SERVER_REQUEST; a_response: SIMPLE_WEB_SERVER_RESPONSE)
    do
        a_response.send_text ("Welcome to my API")
    end

handle_user (a_request: SIMPLE_WEB_SERVER_REQUEST; a_response: SIMPLE_WEB_SERVER_RESPONSE)
    local
        l_id: detachable STRING_32
    do
        l_id := a_request.path_parameter ("id")
        if l_id /= Void then
            -- Fetch user with l_id from database
            a_response.send_json ("{%"id%":" + l_id + ",%"name%":%"John%"}")
        else
            a_response.set_bad_request
            a_response.send_json ("{%"error%":%"Missing id%"}")
        end
    end

create_user (a_request: SIMPLE_WEB_SERVER_REQUEST; a_response: SIMPLE_WEB_SERVER_RESPONSE)
    do
        if attached a_request.body_as_json as l_json then
            -- Process JSON body
            a_response.set_created
            a_response.send_json ("{%"status%":%"created%"}")
        else
            a_response.set_bad_request
            a_response.send_json ("{%"error%":%"Invalid JSON%"}")
        end
    end
```

### Server Response Methods

```eiffel
-- Status setters
a_response.set_ok              -- 200
a_response.set_created         -- 201
a_response.set_no_content      -- 204
a_response.set_bad_request     -- 400
a_response.set_unauthorized    -- 401
a_response.set_forbidden       -- 403
a_response.set_not_found       -- 404
a_response.set_internal_server_error  -- 500

-- Send methods
a_response.send_text ("Hello")
a_response.send_html ("<h1>Hello</h1>")
a_response.send_json ("{%"key%":%"value%"}")
a_response.send_json_object (my_json_object)
a_response.send_empty
a_response.send_redirect ("/other/path")
```

### Server Request Methods

```eiffel
-- Path parameters (from URL pattern like /users/{id})
l_id := a_request.path_parameter ("id")

-- Query parameters (from ?name=value)
l_name := a_request.query_parameter ("name")

-- Headers
l_auth := a_request.header ("Authorization")
l_content_type := a_request.content_type

-- Body
l_body := a_request.body
l_json := a_request.body_as_json

-- Request info
l_method := a_request.method
l_path := a_request.path
if a_request.is_post then ...
```

### Middleware Pipeline

Add middleware to process requests before they reach your handlers:

```eiffel
local
    l_server: SIMPLE_WEB_SERVER
do
    create l_server.make (8080)

    -- Add middleware (runs in order)
    l_server.use (create {SIMPLE_WEB_LOGGING_MIDDLEWARE}.make)
    l_server.use (create {SIMPLE_WEB_CORS_MIDDLEWARE}.make)
    l_server.use (create {SIMPLE_WEB_AUTH_MIDDLEWARE}.make_bearer (agent validate_token))

    -- Register routes
    l_server.on_get ("/api/data", agent handle_data)
    l_server.start
end
```

### Built-in Middleware

**Logging Middleware** - Logs request method and path:
```eiffel
l_server.use (create {SIMPLE_WEB_LOGGING_MIDDLEWARE}.make)
```

**CORS Middleware** - Cross-Origin Resource Sharing:
```eiffel
-- Allow all origins
l_server.use (create {SIMPLE_WEB_CORS_MIDDLEWARE}.make)

-- Allow specific origin
l_server.use (create {SIMPLE_WEB_CORS_MIDDLEWARE}.make_with_origin ("https://example.com"))

-- Allow multiple origins
l_server.use (create {SIMPLE_WEB_CORS_MIDDLEWARE}.make_with_origins (<<"https://a.com", "https://b.com">>))
```

**Auth Middleware** - Authentication:
```eiffel
-- Bearer token validation
l_server.use (create {SIMPLE_WEB_AUTH_MIDDLEWARE}.make_bearer (agent validate_token))

-- Basic auth validation
l_server.use (create {SIMPLE_WEB_AUTH_MIDDLEWARE}.make_basic (agent validate_credentials))

-- API key validation (header-based)
l_server.use (create {SIMPLE_WEB_AUTH_MIDDLEWARE}.make_api_key ("X-API-Key", agent validate_api_key))

-- Exclude paths from auth
l_auth := create {SIMPLE_WEB_AUTH_MIDDLEWARE}.make_bearer (agent validate_token)
l_auth.exclude_path ("/health")
l_auth.exclude_path ("/login")
l_server.use (l_auth)
```

### Custom Middleware

Create custom middleware by inheriting from `SIMPLE_WEB_MIDDLEWARE`:

```eiffel
class MY_CUSTOM_MIDDLEWARE
inherit
    SIMPLE_WEB_MIDDLEWARE

feature -- Access
    name: STRING = "custom"

feature -- Processing
    process (a_request: SIMPLE_WEB_SERVER_REQUEST;
             a_response: SIMPLE_WEB_SERVER_RESPONSE;
             a_next: PROCEDURE)
        do
            -- Pre-processing (before handler)
            print ("Before handler%N")

            -- Call next middleware or handler
            a_next.call (Void)

            -- Post-processing (after handler)
            print ("After handler%N")
        end
end
```

## Architecture

### Client Classes

| Class | Purpose |
|-------|---------|
| `SIMPLE_WEB_CLIENT` | Main HTTP client using libcurl |
| `SIMPLE_WEB_HYBRID_CLIENT` | Hybrid client (curl.exe for POST, libcurl for GET) |
| `SIMPLE_WEB_REQUEST` | Fluent request builder |
| `SIMPLE_WEB_RESPONSE` | Response wrapper with status, headers, body |
| `SIMPLE_WEB_OLLAMA_CLIENT` | Ollama API client |
| `SIMPLE_WEB_CLAUDE_CLIENT` | Claude API client |
| `SIMPLE_WEB_OPENAI_CLIENT` | OpenAI API client |

### Server Classes

| Class | Purpose |
|-------|---------|
| `SIMPLE_WEB_SERVER` | Main server class with route registration |
| `SIMPLE_WEB_SERVER_EXECUTION` | WSF execution handler (dispatches to routes) |
| `SIMPLE_WEB_SERVER_REQUEST` | Request wrapper with path/query params |
| `SIMPLE_WEB_SERVER_RESPONSE` | Response wrapper with send methods |
| `SIMPLE_WEB_SERVER_ROUTE` | Route pattern matching with {param} support |
| `SIMPLE_WEB_SERVER_ROUTER` | Singleton router for route storage |

## Known Issues

### curl_http_client POST to localhost

The EiffelStudio `curl_http_client` library corrupts JSON bodies when POSTing to localhost, causing errors like:

```
{"error":"invalid character 'm' looking for beginning of object key string"}
```

**Workaround:** Use `SIMPLE_WEB_HYBRID_CLIENT` which routes POST/PUT through `curl.exe` process while using libcurl for GET/DELETE.

## Example: WMS REST API Mock

The library includes a full Warehouse Management System (WMS) REST API mock that demonstrates both server and client capabilities. This example uses `simple_sql` for data persistence.

### Server Side (WMS_API_SERVER)

```eiffel
class WMS_API_SERVER inherit SIMPLE_WEB_SERVER

create make_wms

feature {NONE} -- Initialization

    make_wms (a_port: INTEGER; a_app: WMS_APP)
        do
            make (a_port)
            wms_app := a_app
            register_routes
        end

    register_routes
        do
            -- Worker routes
            on_get ("/api/workers", agent handle_get_workers)
            on_post ("/api/workers", agent handle_create_worker)
            on_get ("/api/workers/{id}", agent handle_get_worker)

            -- Task routes
            on_get ("/api/tasks", agent handle_get_tasks)
            on_post ("/api/tasks/{id}/assign", agent handle_assign_task)
            on_post ("/api/tasks/{id}/complete", agent handle_complete_task)

            -- Location routes
            on_get ("/api/locations", agent handle_get_locations)
        end

feature {NONE} -- Handlers

    handle_create_worker (req: SIMPLE_WEB_SERVER_REQUEST; res: SIMPLE_WEB_SERVER_RESPONSE)
        do
            if attached req.body_as_json as l_json then
                if attached l_json.string_item ("name") as l_name then
                    -- Create worker in database
                    res.set_created
                    res.send_json_object (worker_to_json (new_worker))
                else
                    res.send_bad_request ("Missing name field")
                end
            else
                res.send_bad_request ("Invalid JSON body")
            end
        end
end
```

### Client Side (WMS_WORKER_SIMULATOR)

```eiffel
class WMS_WORKER_SIMULATOR

feature -- Simulation

    simulate_work_day
        local
            l_response: SIMPLE_WEB_RESPONSE
        do
            -- Get available tasks
            l_response := client.get (base_url + "/api/tasks?status=pending")

            if l_response.is_success then
                if attached l_response.body_as_json as l_json then
                    -- Process tasks...
                end
            elseif l_response.is_error then
                if attached l_response.error_message as l_msg then
                    print ("Error: " + l_msg + "%N")
                end
            end
        end
end
```

### Running the Mock

```batch
:: Build and run WMS mock tests
ec.exe -batch -config simple_web.ecf -target wms_api_tests -c_compile -freeze
ec.exe -batch -config simple_web.ecf -target wms_api_tests -tests
```

## Testing

95 tests covering:
- Request/response handling
- Integration with httpbin.org, jsonplaceholder.typicode.com
- Ollama API operations
- Hybrid client functionality
- Server route pattern matching
- Server router functionality
- Middleware pipeline tests (12 tests)
- Input sanitization tests (15 tests)

Run tests via EiffelStudio AutoTest.

## Roadmap

### Completed
- [x] HTTP client with fluent request builder
- [x] Hybrid client (curl.exe for POST, libcurl for GET)
- [x] AI clients (Ollama, Claude, OpenAI, Grok)
- [x] HTTP server with agent-based routing
- [x] Path parameter support ({id} placeholders)
- [x] Clean request/response wrapper API
- [x] JSON request/response support
- [x] Mock request/response for testing
- [x] Middleware pipeline system
- [x] Logging middleware
- [x] CORS middleware (allow-all and specific origins)
- [x] Auth middleware (Bearer, Basic, API key)
- [x] Input sanitization (XSS, path traversal, header injection)
- [x] Safe parameter accessors with built-in sanitization
- [x] Todo API mock (demonstrates integration with simple_sql)

### Planned
- [ ] Rate limiting middleware
- [ ] Request validation middleware (JSON schema)
- [ ] Static file serving
- [ ] WebSocket support
- [ ] Session management
- [ ] Cookie handling helpers
- [ ] Multipart form data parsing
- [ ] File upload handling

### Known Issues
- curl_http_client corrupts POST bodies to localhost (use Hybrid client)
- Large response bodies may be truncated by libcurl buffer

## Security

### Input Sanitization

The library provides `SIMPLE_WEB_SANITIZER` for protecting against common attacks:

```eiffel
local
    l_sanitizer: SIMPLE_WEB_SANITIZER
do
    create l_sanitizer

    -- HTML/XSS protection
    l_safe := l_sanitizer.sanitize_html (user_input)  -- Escapes < > & " '
    l_stripped := l_sanitizer.strip_html_tags (user_input)  -- Removes all tags

    -- Path traversal protection
    l_safe_path := l_sanitizer.sanitize_path_parameter (raw_param)  -- Removes .. / \
    if l_sanitizer.is_safe_path_parameter (raw_param) then ...

    -- Header injection protection
    l_safe_header := l_sanitizer.sanitize_header_value (raw_value)  -- Removes CR LF

    -- SQL escaping (prefer parameterized queries)
    l_escaped := l_sanitizer.escape_sql_string (user_input)  -- Doubles single quotes

    -- JSON string escaping
    l_json_safe := l_sanitizer.sanitize_json_string (user_input)  -- Escapes " \ newlines

    -- Length limiting
    l_truncated := l_sanitizer.truncate (user_input, 100)  -- Max 100 chars
end
```

### Safe Parameter Access

The request object provides sanitized versions of parameter accessors:

```eiffel
handle_user (req: SIMPLE_WEB_SERVER_REQUEST; res: SIMPLE_WEB_SERVER_RESPONSE)
    do
        -- Raw access (use with caution)
        l_id := req.path_parameter ("id")

        -- Safe access (sanitizes path traversal)
        l_safe_id := req.safe_path_parameter ("id")

        -- Safe query with length limit
        l_search := req.safe_query_parameter ("q", 100)  -- Max 100 chars, HTML escaped
    end
```

### Security Recommendations

1. **Always use `safe_*` methods** for user-supplied parameters
2. **Validate input types** before using (e.g., check if ID is numeric)
3. **Use parameterized queries** instead of string escaping for SQL
4. **Set Content-Security-Policy headers** for XSS protection
5. **Use HTTPS in production** (configure at proxy/load balancer level)

## License

MIT License - Copyright (c) 2024-2025, Larry Rix
