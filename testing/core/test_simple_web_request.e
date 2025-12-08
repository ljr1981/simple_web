note
	description: "Tests for {SIMPLE_WEB_REQUEST}"
	testing: "covers"

class
	TEST_SIMPLE_WEB_REQUEST

inherit
	EQA_TEST_SET

feature -- Test routines

	test_make_get
			-- Test GET request creation
		note
			testing: "covers/{SIMPLE_WEB_REQUEST}.make_get"
		local
			l_request: SIMPLE_WEB_REQUEST
		do
			create l_request.make_get ("https://api.example.com/test")
			
			assert ("method_is_get", l_request.method ~ "GET")
			assert ("url_set", l_request.url ~ "https://api.example.com/test")
			assert ("body_empty", l_request.body.is_empty)
		end

	test_make_post
			-- Test POST request creation
		note
			testing: "covers/{SIMPLE_WEB_REQUEST}.make_post"
		local
			l_request: SIMPLE_WEB_REQUEST
		do
			create l_request.make_post ("https://api.example.com/test")
			
			assert ("method_is_post", l_request.method ~ "POST")
			assert ("url_set", l_request.url ~ "https://api.example.com/test")
		end

	test_with_header
			-- Test fluent header addition
		note
			testing: "covers/{SIMPLE_WEB_REQUEST}.with_header"
		local
			l_request: SIMPLE_WEB_REQUEST
			l_result: SIMPLE_WEB_REQUEST
		do
			create l_request.make_get ("https://api.example.com/test")
			
			l_result := l_request.with_header ("Content-Type", "application/json")
			
			assert ("returns_self", l_result = l_request)
			assert ("header_added", l_request.headers.has ("Content-Type"))
			assert ("header_value", 
				attached l_request.headers.item ("Content-Type") as al_value and then
				al_value ~ "application/json")
		end

	test_with_json_content_type
			-- Test JSON content type helper
		note
			testing: "covers/{SIMPLE_WEB_REQUEST}.with_json_content_type"
		local
			l_request: SIMPLE_WEB_REQUEST
		do
			create l_request.make_post ("https://api.example.com/test")
			l_request.with_json_content_type.do_nothing
			
			assert ("content_type_set", 
				attached l_request.headers.item ("Content-Type") as al_value and then
				al_value ~ "application/json")
		end

	test_with_bearer_token
			-- Test Bearer token authentication
		note
			testing: "covers/{SIMPLE_WEB_REQUEST}.with_bearer_token"
		local
			l_request: SIMPLE_WEB_REQUEST
			l_token: STRING
		do
			l_token := "sk-test-token-12345"
			create l_request.make_get ("https://api.example.com/test")
			l_request.with_bearer_token (l_token).do_nothing
			
			assert ("auth_header_set", 
				attached l_request.headers.item ("Authorization") as al_value and then
				al_value.has_substring ("Bearer ") and then
				al_value.has_substring (l_token))
		end

	test_with_body
			-- Test body setting
		note
			testing: "covers/{SIMPLE_WEB_REQUEST}.with_body"
		local
			l_request: SIMPLE_WEB_REQUEST
			l_body: STRING
		do
			l_body := "{%"test%":%"data%"}"
			create l_request.make_post ("https://api.example.com/test")
			l_request.with_body (l_body).do_nothing
			
			assert ("body_set", l_request.body ~ l_body)
		end

	test_with_json_body
			-- Test JSON body with content type
		note
			testing: "covers/{SIMPLE_WEB_REQUEST}.with_json_body"
		local
			l_request: SIMPLE_WEB_REQUEST
			l_json: STRING
		do
			l_json := "{%"test%":%"data%"}"
			create l_request.make_post ("https://api.example.com/test")
			l_request.with_json_body (l_json).do_nothing
			
			assert ("body_set", l_request.body ~ l_json)
			assert ("content_type_set", 
				attached l_request.headers.item ("Content-Type") as al_value and then
				al_value ~ "application/json")
		end

	test_with_timeout
			-- Test timeout setting
		note
			testing: "covers/{SIMPLE_WEB_REQUEST}.with_timeout"
		local
			l_request: SIMPLE_WEB_REQUEST
		do
			create l_request.make_get ("https://api.example.com/test")
			l_request.with_timeout (60000).do_nothing
			
			assert ("timeout_set", l_request.timeout_ms = 60000)
		end

	test_fluent_chaining
			-- Test fluent API chaining
		note
			testing: "covers/{SIMPLE_WEB_REQUEST}"
		local
			l_request: SIMPLE_WEB_REQUEST
		do
			create l_request.make_post ("https://api.example.com/test")
			
			l_request.with_bearer_token ("token123")
				.with_json_body ("{%"test%":true}")
				.with_timeout (60000)
				.do_nothing
			
			assert ("method_correct", l_request.method ~ "POST")
			assert ("has_auth", l_request.headers.has ("Authorization"))
			assert ("has_content_type", l_request.headers.has ("Content-Type"))
			assert ("body_set", not l_request.body.is_empty)
			assert ("timeout_set", l_request.timeout_ms = 60000)
		end

note
	copyright: "Copyright (c) 2024-2025, Larry Rix"
	license: "MIT License"
	source: "[
		SIMPLE_WEB - High-level Web API Library
		https://github.com/ljr1981/simple_web
	]"

end
