# SIMPLE_WEB - High-Level Web API Library for Eiffel

A clean, fluent HTTP client library for EiffelStudio that makes RESTful API interactions simple and type-safe.

## Current Status: Alpha (In Development)

**Version:** 0.1.0-alpha  
**Last Updated:** November 21, 2025

### What's Working ✅

- **Core HTTP Methods**: GET, POST, PUT, DELETE operations
- **Fluent Request Builder**: Chainable API for constructing requests
- **Response Handling**: Status codes, headers, body parsing
- **JSON Support**: Automatic Content-Type headers, JSON body parsing via SIMPLE_JSON
- **Error Handling**: Proper handling of network failures (status code 0)
- **Header Management**: Request/response header support with case-insensitive lookup
- **Authentication**: Bearer token and API key helpers

### What's In Progress 🔧

- **JSONPlaceholder Integration Tests**: Some tests passing, investigating POST/PUT failures (likely server-side API changes or encoding issues)
- **Echo Service Tests**: Diagnostic tests using postman-echo.com and httpstat.us
- **Request Body Encoding**: Verifying correct transmission of JSON payloads

### Known Issues ⚠️

1. **POST/PUT Operations**: Getting 500 errors on JSONPlaceholder API - investigating whether issue is client-side encoding or server-side API changes
2. **Header Case Sensitivity**: Response header lookup now case-insensitive, but needs comprehensive testing
3. **Network Failure Handling**: Status code 0 now handled, but needs more edge case testing

## Architecture

```
SIMPLE_WEB/
├── src/
│   ├── client/
│   │   └── simple_web_client.e         # Main HTTP client
│   ├── core/
│   │   ├── simple_web_request.e        # Fluent request builder
│   │   └── simple_web_response.e       # Response wrapper
│   ├── constants/
│   │   └── simple_web_constants.e      # HTTP constants, status codes
│   └── ai/
│       ├── simple_web_openai_client.e  # OpenAI API wrapper (planned)
│       └── simple_web_claude_client.e  # Claude API wrapper (planned)
└── testing/
    ├── client/
    │   ├── test_simple_web_client_integration.e
    │   └── test_simple_web_client_jsonplaceholder.e
    └── core/
        ├── test_simple_web_client_echo.e
        ├── test_simple_web_request.e
        └── test_simple_web_response.e
```

## Quick Start

### Basic GET Request

```eiffel
local
    l_client: SIMPLE_WEB_CLIENT
    l_response: SIMPLE_WEB_RESPONSE
do
    create l_client.make
    l_response := l_client.get ("https://api.example.com/data")
    
    if l_response.is_success then
        print (l_response.body)
    end
end
```

### POST with JSON

```eiffel
local
    l_client: SIMPLE_WEB_CLIENT
    l_response: SIMPLE_WEB_RESPONSE
    l_json: STRING
do
    l_json := "{%"name%":%"Alice%",%"age%":30}"
    
    create l_client.make
    l_response := l_client.post_json ("https://api.example.com/users", l_json)
    
    if l_response.is_success then
        print ("Created: " + l_response.body)
    end
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
    
    l_request.with_json_body ("{%"data%":%"value%"}")
        .with_bearer_token ("your-api-token")
        .with_header ("X-Custom", "value")
        .do_nothing
    
    l_response := l_client.execute (l_request)
end
```

### Response Handling

```eiffel
local
    l_response: SIMPLE_WEB_RESPONSE
    l_json: detachable SIMPLE_JSON_VALUE
do
    -- Check status
    if l_response.is_success then          -- 2xx status
        -- Success handling
    elseif l_response.is_client_error then -- 4xx status
        -- Client error handling
    elseif l_response.is_server_error then -- 5xx status
        -- Server error handling
    end
    
    -- Parse JSON response
    l_json := l_response.body_as_json
    if attached l_json as al_json and then al_json.is_object then
        -- Process JSON object
    end
    
    -- Access headers (case-insensitive)
    if l_response.has_header ("content-type") then
        print (l_response.header ("Content-Type"))
    end
end
```

## Dependencies

- **EiffelStudio 25.02** or later
- **SIMPLE_JSON Library**: For JSON parsing/generation
- **EiffelNet**: HTTP client library (CURL_HTTP_CLIENT_SESSION)

## Roadmap to v1.0

### Phase 1: Core Stability (Current)
- [x] Basic HTTP methods (GET, POST, PUT, DELETE)
- [x] Fluent request builder API
- [x] Response handling with headers
- [x] JSON content type handling
- [x] Status code 0 (network failure) handling
- [x] Header case-insensitive lookup
- [ ] Debug POST/PUT encoding issues
- [ ] Complete echo service diagnostic tests
- [ ] Verify all JSONPlaceholder tests pass

### Phase 2: Enhanced Features
- [ ] Query parameter builder
- [ ] Form data encoding
- [ ] Multipart file upload
- [ ] Request/response interceptors
- [ ] Timeout configuration
- [ ] Retry logic with exponential backoff
- [ ] Response streaming for large payloads

### Phase 3: AI Client Libraries
- [ ] OpenAI API client wrapper
- [ ] Claude API client wrapper
- [ ] Common patterns for AI APIs
- [ ] Streaming support for chat completions

### Phase 4: Production Release
- [ ] Comprehensive documentation
- [ ] Performance benchmarks
- [ ] Security audit
- [ ] Error handling best practices guide
- [ ] Example applications
- [ ] v1.0.0 release

## Testing

Run tests using EiffelStudio's AutoTest:

```bash
# Open simple_web.ecf in EiffelStudio
# Navigate to Testing tool
# Run all tests or specific test classes
```

**Test Suites:**
- `TEST_SIMPLE_WEB_REQUEST` - Request builder unit tests
- `TEST_SIMPLE_WEB_RESPONSE` - Response handling unit tests
- `TEST_SIMPLE_WEB_CLIENT_ECHO` - Echo service diagnostic tests
- `TEST_SIMPLE_WEB_CLIENT_JSONPLACEHOLDER` - Integration tests (partial)
- `TEST_SIMPLE_WEB_CLIENT_INTEGRATION` - Full integration scenarios

## Contributing

This is currently in active development. Issues and pull requests welcome.

### Development Principles

1. **Design by Contract**: All features use comprehensive preconditions/postconditions
2. **Void-Safety**: 100% void-safe codebase
3. **Command-Query Separation**: Strict adherence to CQS principles
4. **Fluent APIs**: Chainable methods for better developer experience
5. **Test Coverage**: Every feature has corresponding tests

## License

MIT License - Copyright (c) 2024-2025, Larry Rix

## Acknowledgments

Built on EiffelStudio's robust HTTP client infrastructure.  
Inspired by modern HTTP client libraries across languages.

---

**Note:** This library is under active development. APIs may change before v1.0 release.
