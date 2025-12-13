<p align="center">
  <img src="https://raw.githubusercontent.com/simple-eiffel/claude_eiffel_op_docs/main/artwork/LOGO.png" alt="simple_ library logo" width="400">
</p>

# simple_web

**[Documentation](https://simple-eiffel.github.io/simple_web/)** | **[GitHub](https://github.com/simple-eiffel/simple_web)**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Eiffel](https://img.shields.io/badge/Eiffel-25.02-blue.svg)](https://www.eiffel.org/)
[![Design by Contract](https://img.shields.io/badge/DbC-enforced-orange.svg)]()

High-level HTTP client and server library for Eiffel applications.

Part of the [Simple Eiffel](https://github.com/simple-eiffel) ecosystem.

## Status

**Production** - HTTP client and server both working

## Overview

SIMPLE_WEB provides clean APIs for HTTP client operations and HTTP server development. Includes ready-to-use clients for Ollama, Claude, OpenAI, and Grok AI services.

```eiffel
local
    client: SIMPLE_WEB_CLIENT
    response: SIMPLE_WEB_RESPONSE
do
    create client.make
    response := client.get ("https://api.example.com/data")
    if response.is_success then
        print (response.body)
    end
end
```

## Features

- **HTTP Client** - GET, POST, PUT, DELETE with fluent builder
- **HTTP Server** - Agent-based routing with path parameters
- **JSON Support** - Easy JSON request/response handling
- **AI Clients** - Ollama, Claude, OpenAI, Grok integrations
- **Hybrid Client** - Workaround for localhost POST issues
- **Resilience Patterns** - Circuit breaker, bulkhead, retry with backoff, timeout, fallback

## Installation

1. Set environment variable:
```bash
export SIMPLE_WEB=/path/to/simple_web
```

2. Add to ECF:
```xml
<library name="simple_web" location="$SIMPLE_WEB/simple_web.ecf"/>
```

## Dependencies

- simple_json
- simple_process
- simple_datetime
- EWF libraries (included with EiffelStudio)

## License

MIT License
