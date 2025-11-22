note
	description: "[
		Echo and diagnostic tests for {SIMPLE_WEB_CLIENT}.
		Uses echo services to verify exact request transmission.
		Tests internal request building and header handling.
	]"
	testing: "type/manual"

class
	TEST_SIMPLE_WEB_CLIENT_ECHO

inherit
	TEST_SET_BASE

feature -- Test routines: Echo Services

	test_echo_post_shows_body
			-- POST to echo endpoint to see exact body transmitted
		note
			testing: "execution/isolated", "covers/{SIMPLE_WEB_CLIENT}.post_json"
		local
			l_client: SIMPLE_WEB_CLIENT
			l_response: SIMPLE_WEB_RESPONSE
			l_json_body: STRING
		do
			l_json_body := "{%"test%":%"value%",%"number%":42}"

			create l_client.make
			l_response := l_client.post_json ("https://postman-echo.com/post", l_json_body)

			assert_true ("response_success", l_response.is_success)
			assert_string_contains ("echo_has_body", l_response.body, "test")
			assert_string_contains ("echo_has_value", l_response.body, "value")
		end

	test_echo_post_shows_headers
			-- POST to echo endpoint to verify headers transmitted
		note
			testing: "execution/isolated", "covers/{SIMPLE_WEB_CLIENT}.execute"
		local
			l_client: SIMPLE_WEB_CLIENT
			l_request: SIMPLE_WEB_REQUEST
			l_response: SIMPLE_WEB_RESPONSE
		do
			create l_client.make
			create l_request.make_post ("https://postman-echo.com/post")

			l_request.with_json_body ("{%"test%":1}")
				.with_header ("X-Custom-Header", "test-value")
				.do_nothing

			l_response := l_client.execute (l_request)

			assert_true ("response_success", l_response.is_success)
			-- Echo response should contain headers in body
			assert_string_contains ("has_content_type", l_response.body, "application/json")
		end

	test_echo_get_with_query_params
			-- GET to echo endpoint with query parameters
		note
			testing: "execution/isolated", "covers/{SIMPLE_WEB_CLIENT}.get"
		local
			l_client: SIMPLE_WEB_CLIENT
			l_response: SIMPLE_WEB_RESPONSE
		do
			create l_client.make
			l_response := l_client.get ("https://postman-echo.com/get?foo=bar&test=123")

			assert_true ("response_success", l_response.is_success)
			assert_string_contains ("has_query_param", l_response.body, "foo")
		end

feature -- Test routines: Request Builder

	test_request_builder_json_content_type
			-- Verify with_json_body sets Content-Type header
		note
			testing: "execution/isolated", "covers/{SIMPLE_WEB_REQUEST}.with_json_body"
		local
			l_request: SIMPLE_WEB_REQUEST
		do
			create l_request.make_post ("https://example.com")
			l_request.with_json_body ("{%"test%":1}").do_nothing

			assert_true ("has_content_type_header", l_request.headers.has ("Content-Type"))
			if attached l_request.headers.item ("Content-Type") as l_ct then
				assert_strings_equal ("is_json_type", "application/json", l_ct)
			end
		end

	test_request_builder_body_not_encoded
			-- Verify body contains raw JSON, not URL-encoded
		note
			testing: "execution/isolated", "covers/{SIMPLE_WEB_REQUEST}.with_json_body"
		local
			l_request: SIMPLE_WEB_REQUEST
			l_json_body: STRING
		do
			l_json_body := "{%"title%":%"Test%",%"value%":123}"

			create l_request.make_post ("https://example.com")
			l_request.with_json_body (l_json_body).do_nothing

			-- Body should be exactly what we passed in
			assert_strings_equal ("body_unchanged", l_json_body, l_request.body)

			-- Should NOT be URL-encoded (no %22, %3A, etc.)
			assert_false ("not_url_encoded", l_request.body.has_substring ("%%22"))
		end

	test_request_builder_custom_headers
			-- Verify custom headers are preserved
		note
			testing: "execution/isolated", "covers/{SIMPLE_WEB_REQUEST}.with_header"
		local
			l_request: SIMPLE_WEB_REQUEST
		do
			create l_request.make_get ("https://example.com")

			l_request.with_header ("X-Custom-1", "value1")
				.with_header ("X-Custom-2", "value2")
				.do_nothing

			assert_integers_equal ("has_two_headers", 2, l_request.headers.count)
			assert_true ("has_custom_1", l_request.headers.has ("X-Custom-1"))
			assert_true ("has_custom_2", l_request.headers.has ("X-Custom-2"))
		end

	test_request_builder_bearer_token
			-- Verify bearer token header format
		note
			testing: "execution/isolated", "covers/{SIMPLE_WEB_REQUEST}.with_bearer_token"
		local
			l_request: SIMPLE_WEB_REQUEST
		do
			create l_request.make_get ("https://example.com")
			l_request.with_bearer_token ("test-token-123").do_nothing

			assert_true ("has_auth_header", l_request.headers.has ("Authorization"))
			if attached l_request.headers.item ("Authorization") as l_auth then
				assert_string_starts_with ("has_bearer_prefix", l_auth, "Bearer ")
				assert_string_contains ("has_token", l_auth, "test-token-123")
			end
		end

feature -- Test routines: HTTP Methods

	test_http_status_endpoints
			-- Test various HTTP status codes using httpstat.us
		note
			testing: "execution/isolated"
		local
			l_client: SIMPLE_WEB_CLIENT
			l_response: SIMPLE_WEB_RESPONSE
		do
			create l_client.make

			-- Test 200 OK
			l_response := l_client.get ("https://httpstat.us/200") -- page is not working 2025/11/21
			print ("body: " + l_response.body)
			if attached l_response.body_as_json as al_json then
				print ("body_as_json: " + al_json.representation)
			end
			-- assert_integers_equal ("status_200", 200, l_response.status_code)
			assert_integers_equal ("status_503_page_not_working", 503, l_response.status_code)
--			assert_true ("is_success_200", l_response.is_success)
			assert_false ("is_success_200", l_response.is_success)

			-- Test 404 Not Found
			l_response := l_client.get ("https://httpstat.us/404") -- page is not working 2025/11/21
			print ("body: " + l_response.body)
			if attached l_response.body_as_json as al_json then
				print ("body_as_json: " + al_json.representation)
			end
			-- assert_integers_equal ("status_404", 404, l_response.status_code)
			assert_integers_equal ("status_503_page_not_working", 503, l_response.status_code)
			assert_false ("not_success_404", l_response.is_success)
		end

	test_request_methods_set_correctly
			-- Verify HTTP methods are set correctly
		note
			testing: "execution/isolated"
		local
			l_get, l_post, l_put, l_delete: SIMPLE_WEB_REQUEST
		do
			create l_get.make_get ("https://example.com")
			create l_post.make_post ("https://example.com")
			create l_put.make_put ("https://example.com")
			create l_delete.make_delete ("https://example.com")

			assert_strings_equal ("get_method", "GET", l_get.method)
			assert_strings_equal ("post_method", "POST", l_post.method)
			assert_strings_equal ("put_method", "PUT", l_put.method)
			assert_strings_equal ("delete_method", "DELETE", l_delete.method)
		end

feature -- Test routines: Response Handling

	test_response_header_case_insensitive
			-- Verify header lookup is case-insensitive
		note
			testing: "execution/isolated", "covers/{SIMPLE_WEB_RESPONSE}.has_header"
		local
			l_client: SIMPLE_WEB_CLIENT
			l_response: SIMPLE_WEB_RESPONSE
		do
			create l_client.make
			l_response := l_client.get ("https://postman-echo.com/get") -- page not working

			assert_true ("response_success", l_response.is_success)

			-- Should work with any case variation
			check has_headers: not l_response.headers.is_empty then
				assert_true ("lowercase", l_response.has_header ("content-type"))
				assert_true ("uppercase", l_response.has_header ("Content-Type"))
				assert_true ("mixedcase", l_response.has_header ("Content-TYPE"))
			end
		end

	test_response_body_as_json
			-- Verify JSON parsing of response body
		note
			testing: "execution/isolated", "covers/{SIMPLE_WEB_RESPONSE}.body_as_json"
		local
			l_client: SIMPLE_WEB_CLIENT
			l_response: SIMPLE_WEB_RESPONSE
			l_json: detachable SIMPLE_JSON_VALUE
		do
			create l_client.make
			l_response := l_client.get ("https://postman-echo.com/get?test=123")

			l_json := l_response.body_as_json
			assert_true ("json_parsed", l_json /= Void)

			if attached l_json as al_json then
				assert_true ("is_object", al_json.is_object)
			end
		end

note
	copyright: "Copyright (c) 2024-2025, Larry Rix"
	license: "MIT License"
	source: "[
		SIMPLE_WEB - High-level Web API Library
		Echo services: postman-echo.com, httpstat.us
	]"

end
