note
	description: "Tests for SIMPLE_WEB"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"
	testing: "covers"

class
	LIB_TESTS

inherit
	TEST_SET_BASE

feature -- Test: Request Creation

	test_make_get_request
			-- Test GET request creation.
		note
			testing: "covers/{SIMPLE_WEB_REQUEST}.make_get"
		local
			request: SIMPLE_WEB_REQUEST
		do
			create request.make_get ("https://example.com/api")
			assert_strings_equal ("method", "GET", request.method)
			assert_strings_equal ("url", "https://example.com/api", request.url)
			assert_true ("body empty", request.body.is_empty)
		end

	test_make_post_request
			-- Test POST request creation.
		note
			testing: "covers/{SIMPLE_WEB_REQUEST}.make_post"
		local
			request: SIMPLE_WEB_REQUEST
		do
			create request.make_post ("https://example.com/api")
			assert_strings_equal ("method", "POST", request.method)
		end

	test_make_put_request
			-- Test PUT request creation.
		note
			testing: "covers/{SIMPLE_WEB_REQUEST}.make_put"
		local
			request: SIMPLE_WEB_REQUEST
		do
			create request.make_put ("https://example.com/api")
			assert_strings_equal ("method", "PUT", request.method)
		end

	test_make_delete_request
			-- Test DELETE request creation.
		note
			testing: "covers/{SIMPLE_WEB_REQUEST}.make_delete"
		local
			request: SIMPLE_WEB_REQUEST
		do
			create request.make_delete ("https://example.com/api")
			assert_strings_equal ("method", "DELETE", request.method)
		end

feature -- Test: Request Headers

	test_with_header
			-- Test adding custom header.
		note
			testing: "covers/{SIMPLE_WEB_REQUEST}.with_header"
		local
			request: SIMPLE_WEB_REQUEST
		do
			create request.make_get ("https://example.com")
			request.with_header ("X-Custom", "value").do_nothing
			assert_true ("has header", request.headers.has ("X-Custom"))
		end

	test_with_json_content_type
			-- Test JSON content type helper.
		note
			testing: "covers/{SIMPLE_WEB_REQUEST}.with_json_content_type"
		local
			request: SIMPLE_WEB_REQUEST
		do
			create request.make_post ("https://example.com")
			request.with_json_content_type.do_nothing
			assert_true ("has content-type", request.headers.has ("Content-Type"))
		end

	test_with_bearer_token
			-- Test bearer token authentication.
		note
			testing: "covers/{SIMPLE_WEB_REQUEST}.with_bearer_token"
		local
			request: SIMPLE_WEB_REQUEST
		do
			create request.make_get ("https://example.com")
			request.with_bearer_token ("my-token").do_nothing
			assert_true ("has auth header", request.headers.has ("Authorization"))
		end

feature -- Test: Request Body

	test_with_body
			-- Test setting request body.
		note
			testing: "covers/{SIMPLE_WEB_REQUEST}.with_body"
		local
			request: SIMPLE_WEB_REQUEST
		do
			create request.make_post ("https://example.com")
			request.with_body ("{%"key%": %"value%"}").do_nothing
			assert_false ("body not empty", request.body.is_empty)
			assert_string_contains ("has key", request.body, "key")
		end

feature -- Test: Response Creation

	test_response_make
			-- Test response creation.
		note
			testing: "covers/{SIMPLE_WEB_RESPONSE}.make_with_body"
		local
			response: SIMPLE_WEB_RESPONSE
		do
			create response.make_with_body (200, "OK")
			assert_integers_equal ("status code", 200, response.status_code)
			assert_strings_equal ("body", "OK", response.body)
		end

	test_response_is_success
			-- Test success status check.
		note
			testing: "covers/{SIMPLE_WEB_RESPONSE}.is_success"
		local
			response: SIMPLE_WEB_RESPONSE
		do
			create response.make (200)
			assert_true ("200 is success", response.is_success)
			create response.make (201)
			assert_true ("201 is success", response.is_success)
			create response.make (404)
			assert_false ("404 not success", response.is_success)
		end

	test_response_is_client_error
			-- Test client error status check.
		note
			testing: "covers/{SIMPLE_WEB_RESPONSE}.is_client_error"
		local
			response: SIMPLE_WEB_RESPONSE
		do
			create response.make (400)
			assert_true ("400 is client error", response.is_client_error)
			create response.make (404)
			assert_true ("404 is client error", response.is_client_error)
			create response.make (500)
			assert_false ("500 not client error", response.is_client_error)
		end

	test_response_is_server_error
			-- Test server error status check.
		note
			testing: "covers/{SIMPLE_WEB_RESPONSE}.is_server_error"
		local
			response: SIMPLE_WEB_RESPONSE
		do
			create response.make (500)
			assert_true ("500 is server error", response.is_server_error)
			create response.make (503)
			assert_true ("503 is server error", response.is_server_error)
			create response.make (400)
			assert_false ("400 not server error", response.is_server_error)
		end

feature -- Test: Client Creation

	test_client_make
			-- Test client creation.
		note
			testing: "covers/{SIMPLE_WEB_CLIENT}.make"
		local
			client: SIMPLE_WEB_CLIENT
		do
			create client.make
			assert_attached ("client created", client)
		end

end
