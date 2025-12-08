note
	description: "Tests for {SIMPLE_WEB_RESPONSE}"
	testing: "covers"

class
	TEST_SIMPLE_WEB_RESPONSE

inherit
	EQA_TEST_SET

feature -- Test routines

	test_make
			-- Test basic initialization
		note
			testing: "covers/{SIMPLE_WEB_RESPONSE}.make"
		local
			l_response: SIMPLE_WEB_RESPONSE
		do
			create l_response.make (200)
			
			assert ("status_set", l_response.status_code = 200)
			assert ("body_empty", l_response.body.is_empty)
			assert ("headers_attached", l_response.headers /= Void)
		end

	test_make_with_body
			-- Test initialization with body
		note
			testing: "covers/{SIMPLE_WEB_RESPONSE}.make_with_body"
		local
			l_response: SIMPLE_WEB_RESPONSE
			l_body: STRING
		do
			l_body := "Test response body"
			create l_response.make_with_body (200, l_body)
			
			assert ("status_set", l_response.status_code = 200)
			assert ("body_set", l_response.body ~ l_body)
		end

	test_is_success
			-- Test success status detection
		note
			testing: "covers/{SIMPLE_WEB_RESPONSE}.is_success"
		local
			l_response: SIMPLE_WEB_RESPONSE
		do
			-- 2xx statuses are success
			create l_response.make (200)
			assert ("200_is_success", l_response.is_success)
			
			create l_response.make (201)
			assert ("201_is_success", l_response.is_success)
			
			create l_response.make (299)
			assert ("299_is_success", l_response.is_success)
			
			-- Other statuses are not success
			create l_response.make (400)
			assert ("400_not_success", not l_response.is_success)
			
			create l_response.make (500)
			assert ("500_not_success", not l_response.is_success)
		end

	test_is_ok
			-- Test 200 OK detection
		note
			testing: "covers/{SIMPLE_WEB_RESPONSE}.is_ok"
		local
			l_response: SIMPLE_WEB_RESPONSE
		do
			create l_response.make (200)
			assert ("200_is_ok", l_response.is_ok)
			
			create l_response.make (201)
			assert ("201_not_ok", not l_response.is_ok)
		end

	test_is_client_error
			-- Test client error detection
		note
			testing: "covers/{SIMPLE_WEB_RESPONSE}.is_client_error"
		local
			l_response: SIMPLE_WEB_RESPONSE
		do
			create l_response.make (400)
			assert ("400_is_client_error", l_response.is_client_error)
			
			create l_response.make (404)
			assert ("404_is_client_error", l_response.is_client_error)
			
			create l_response.make (200)
			assert ("200_not_client_error", not l_response.is_client_error)
		end

	test_is_server_error
			-- Test server error detection
		note
			testing: "covers/{SIMPLE_WEB_RESPONSE}.is_server_error"
		local
			l_response: SIMPLE_WEB_RESPONSE
		do
			create l_response.make (500)
			assert ("500_is_server_error", l_response.is_server_error)
			
			create l_response.make (503)
			assert ("503_is_server_error", l_response.is_server_error)
			
			create l_response.make (200)
			assert ("200_not_server_error", not l_response.is_server_error)
		end

	test_add_header
			-- Test adding headers
		note
			testing: "covers/{SIMPLE_WEB_RESPONSE}.add_header",
					 "covers/{SIMPLE_WEB_RESPONSE}.has_header",
					 "covers/{SIMPLE_WEB_RESPONSE}.header"
		local
			l_response: SIMPLE_WEB_RESPONSE
		do
			create l_response.make (200)
			
			l_response.add_header ("Content-Type", "application/json")
			
			assert ("has_header", l_response.has_header ("Content-Type"))
			assert ("header_value", 
				attached l_response.header ("Content-Type") as al_value and then
				al_value ~ "application/json")
		end

	test_body_as_json
			-- Test JSON parsing
		note
			testing: "covers/{SIMPLE_WEB_RESPONSE}.body_as_json"
		local
			l_response: SIMPLE_WEB_RESPONSE
			l_json: STRING
		do
			l_json := "{%"status%":%"ok%",%" message%":%"success%"}"
			create l_response.make_with_body (200, l_json)
			
			if attached l_response.body_as_json as al_json then
				assert ("json_parsed", al_json /= Void)
				assert ("json_is_object", al_json.is_object)
			else
				assert ("json_should_parse", False)
			end
		end

note
	copyright: "Copyright (c) 2024-2025, Larry Rix"
	license: "MIT License"
	source: "[
		SIMPLE_WEB - High-level Web API Library
		https://github.com/ljr1981/simple_web
	]"

end
