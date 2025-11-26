# SIMPLE_WEB

High-level HTTP client library for Eiffel, providing clean APIs for REST operations and AI service integration.

## Features

- **Fluent request builder** - chainable API for constructing HTTP requests
- **JSON support** - easy POST/PUT with JSON bodies
- **AI clients** - ready-to-use clients for Ollama, Claude, OpenAI, and Grok
- **Response handling** - structured access to status, headers, and body

## Installation

Add to your ECF:

```xml
<library name="simple_web" location="path/to/simple_web/simple_web.ecf"/>
```

### Dependencies

- EiffelStudio 25.02+
- `curl_http_client` library (included with EiffelStudio)
- `curl.exe` available on PATH (for hybrid client)
- `framework` library

## Usage

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

## Architecture

| Class | Purpose |
|-------|---------|
| `SIMPLE_WEB_CLIENT` | Main HTTP client using libcurl |
| `SIMPLE_WEB_HYBRID_CLIENT` | Hybrid client (curl.exe for POST, libcurl for GET) |
| `SIMPLE_WEB_REQUEST` | Fluent request builder |
| `SIMPLE_WEB_RESPONSE` | Response wrapper with status, headers, body |
| `SIMPLE_WEB_OLLAMA_CLIENT` | Ollama API client |
| `SIMPLE_WEB_CLAUDE_CLIENT` | Claude API client |
| `SIMPLE_WEB_OPENAI_CLIENT` | OpenAI API client |

## Known Issues

### curl_http_client POST to localhost

The EiffelStudio `curl_http_client` library corrupts JSON bodies when POSTing to localhost, causing errors like:

```
{"error":"invalid character 'm' looking for beginning of object key string"}
```

**Workaround:** Use `SIMPLE_WEB_HYBRID_CLIENT` which routes POST/PUT through `curl.exe` process while using libcurl for GET/DELETE.

## Testing

59 tests covering:
- Request/response handling
- Integration with httpbin.org, jsonplaceholder.typicode.com
- Ollama API operations
- Hybrid client functionality

Run tests via EiffelStudio AutoTest.

## License

MIT License - Copyright (c) 2024-2025, Larry Rix
