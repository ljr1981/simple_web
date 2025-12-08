note
	description: "[
		Integration tests for {SIMPLE_WEB_CLIENT} using httpbin.org.
		Tests real HTTPS requests, authentication, and error handling.
	]"
	testing: "covers"

class
	TEST_SIMPLE_WEB_CLIENT_INTEGRATION

inherit
	TEST_SET_BASE

feature -- Test routines: GET

	test_get_httpbin
			-- Test basic GET request
		note
			testing: "execution/isolated", "covers/{SIMPLE_WEB_CLIENT}.get"
		local
			l_client: SIMPLE_WEB_CLIENT
			l_response: SIMPLE_WEB_RESPONSE
		do
			create l_client.make
			l_response := l_client.get ("https://httpbin.org/get")

			print (l_response.body)

			assert ("response_attached", l_response /= Void)
			assert ("is_success", l_response.is_success)
			assert ("is_200_ok", l_response.is_ok)
			assert ("has_body", not l_response.body.is_empty)
		end

	test_get_with_query_params
			-- Test GET with query parameters
		note
			testing: "execution/isolated", "covers/{SIMPLE_WEB_CLIENT}.get"
		local
			l_client: SIMPLE_WEB_CLIENT
			l_response: SIMPLE_WEB_RESPONSE
		do
			create l_client.make
			l_response := l_client.get ("https://httpbin.org/get?test=value&foo=bar")

			print (l_response.body)

			assert ("response_success", l_response.is_success)
			assert ("body_contains_params",
				l_response.body.has_substring ("test") and
				l_response.body.has_substring ("value"))
		end

feature -- Test routines: POST

	test_post_json_httpbin
			-- Test POST with JSON body
		note
			testing: "execution/isolated", "covers/{SIMPLE_WEB_CLIENT}.post_json"
		local
			l_client: SIMPLE_WEB_CLIENT
			l_response: SIMPLE_WEB_RESPONSE
			l_json: STRING
		do
			l_json := "{%"name%":%"test%",%"value%":123}"

			create l_client.make
			l_response := l_client.post_json ("https://httpbin.org/post", l_json)

			print (l_response.body)

			assert ("response_attached", l_response /= Void)
			assert ("is_success", l_response.is_success)
			assert ("body_echoes_json",
				l_response.body.has_substring ("test") and
				l_response.body.has_substring ("123"))
		end

	test_post_with_fluent_api
			-- Test POST using fluent request builder
		note
			testing: "execution/isolated",
					 "covers/{SIMPLE_WEB_CLIENT}.execute",
					 "covers/{SIMPLE_WEB_REQUEST}"
		local
			l_client: SIMPLE_WEB_CLIENT
			l_request: SIMPLE_WEB_REQUEST
			l_response: SIMPLE_WEB_RESPONSE
		do
			create l_client.make
			create l_request.make_post ("https://httpbin.org/post")

			l_request.with_json_body ("{%"fluent%":true}")
				.with_header ("X-Custom-Header", "test-value")
				.do_nothing

			l_response := l_client.execute (l_request)

			print (l_response.body)

			assert ("response_success", l_response.is_success)
			assert ("body_has_data", l_response.body.has_substring ("fluent"))
		end

feature -- Test routines: Authentication

	test_bearer_auth_httpbin
			-- Test Bearer token authentication
		note
			testing: "execution/isolated",
					 "covers/{SIMPLE_WEB_REQUEST}.with_bearer_token"
		local
			l_client: SIMPLE_WEB_CLIENT
			l_request: SIMPLE_WEB_REQUEST
			l_response: SIMPLE_WEB_RESPONSE
		do
			create l_client.make
			create l_request.make_get ("https://httpbin.org/bearer")

			l_request.with_bearer_token ("test-token-12345").do_nothing

			l_response := l_client.execute (l_request)

			print (l_response.body)

			assert ("auth_success", l_response.is_success)
			assert ("token_echoed", l_response.body.has_substring ("test-token-12345"))
		end

feature -- Test routines: Status Codes

	test_status_404_httpbin
			-- Test 404 Not Found status
		note
			testing: "execution/isolated",
					 "covers/{SIMPLE_WEB_RESPONSE}.is_client_error"
		local
			l_client: SIMPLE_WEB_CLIENT
			l_response: SIMPLE_WEB_RESPONSE
		do
			create l_client.make
			l_response := l_client.get ("https://httpbin.org/status/404")

			print (l_response.body)

			assert ("response_attached", l_response /= Void)
			assert ("not_success", not l_response.is_success)
			assert ("is_client_error", l_response.is_client_error)
			assert ("status_is_404", l_response.status_code = 404)
		end

	test_status_500_httpbin
			-- Test 500 Internal Server Error status
		note
			testing: "execution/isolated",
					 "covers/{SIMPLE_WEB_RESPONSE}.is_server_error"
		local
			l_client: SIMPLE_WEB_CLIENT
			l_response: SIMPLE_WEB_RESPONSE
		do
			create l_client.make
			l_response := l_client.get ("https://httpbin.org/status/500")

			print (l_response.body)

			assert ("response_attached", l_response /= Void)
			assert ("not_success", not l_response.is_success)
			assert ("is_server_error", l_response.is_server_error)
			assert ("status_is_500", l_response.status_code = 500)
		end

feature -- Test routines: Headers

	test_custom_headers
			-- Test custom header setting
		note
			testing: "execution/isolated",
					 "covers/{SIMPLE_WEB_REQUEST}.with_header"
		local
			l_client: SIMPLE_WEB_CLIENT
			l_request: SIMPLE_WEB_REQUEST
			l_response: SIMPLE_WEB_RESPONSE
		do
			create l_client.make
			create l_request.make_get ("https://httpbin.org/headers")

			l_request.with_header ("X-Test-Header", "test-value-123")
				.with_header ("X-Another-Header", "another-value")
				.do_nothing

			l_response := l_client.execute (l_request)

			print (l_response.body)

			assert ("response_success", l_response.is_success)

			--{
			--  "headers": {
			--    "Accept": "*/*",
			--    "Another-Value": "another-value",
			--    "Host": "httpbin.org",
			--    "Test-Value-123": "test-value-123",
			--    "User-Agent": "curl/8.16.0",
			--    "X-Amzn-Trace-Id": "Root=1-6920e80e-677173554d5b6be4606db23f"
			--  }
			--}

			assert ("header_echoed",
				l_response.body.has_substring ("X-Amzn-Trace-Id") and
				l_response.body.has_substring ("test-value-123"))
		end

feature -- Test routines: JSON Parsing

	test_json_response_parsing
			-- Test JSON response parsing
		note
			testing: "execution/isolated",
					 "covers/{SIMPLE_WEB_RESPONSE}.body_as_json"
		local
			l_client: SIMPLE_WEB_CLIENT
			l_response: SIMPLE_WEB_RESPONSE
			l_json: detachable SIMPLE_JSON_VALUE
		do
			create l_client.make
			l_response := l_client.get ("https://httpbin.org/json")

			assert ("response_success", l_response.is_success)

			l_json := l_response.body_as_json

			print (l_response.body)

			assert ("json_parsed", l_json /= Void)
			if attached l_json as al_json then
				assert ("json_is_object", al_json.is_object)
			end
		end

feature -- Test routines: Timeouts

	test_timeout_handling
			-- Test timeout configuration (use short delay)
		note
			testing: "execution/isolated",
					 "covers/{SIMPLE_WEB_REQUEST}.with_timeout"
		local
			l_client: SIMPLE_WEB_CLIENT
			l_request: SIMPLE_WEB_REQUEST
			l_response: SIMPLE_WEB_RESPONSE
		do
			create l_client.make
			create l_request.make_get ("https://httpbin.org/delay/1")

			-- Set reasonable timeout that should succeed
			l_request.with_timeout (10000).do_nothing  -- 10 seconds

			l_response := l_client.execute (l_request)

			print (l_response.body)

			assert ("response_attached", l_response /= Void)
			-- Should succeed with 10 second timeout on 1 second delay
			assert ("request_completed", l_response.is_success)
		end

note
	copyright: "Copyright (c) 2024-2025, Larry Rix"
	license: "MIT License"
	source: "[
		SIMPLE_WEB - High-level Web API Library
		https://github.com/ljr1981/simple_web
	]"

end
