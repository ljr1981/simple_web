note
	description: "Tests for {SIMPLE_WEB_SERVER_ROUTE} pattern matching"
	testing: "covers"

class
	TEST_SIMPLE_WEB_SERVER_ROUTE

inherit
	TEST_SET_BASE

feature -- Test routines

	test_exact_path_match
			-- Test exact path matching
		note
			testing: "covers/{SIMPLE_WEB_SERVER_ROUTE}.matches"
		local
			l_route: SIMPLE_WEB_SERVER_ROUTE
		do
			create l_route.make ("GET", "/api/users", agent dummy_handler)

			assert ("matches_exact", l_route.matches ("GET", "/api/users"))
			assert ("no_match_different_path", not l_route.matches ("GET", "/api/posts"))
			assert ("no_match_different_method", not l_route.matches ("POST", "/api/users"))
		end

	test_path_with_parameter
			-- Test path parameter matching
		note
			testing: "covers/{SIMPLE_WEB_SERVER_ROUTE}.matches"
		local
			l_route: SIMPLE_WEB_SERVER_ROUTE
		do
			create l_route.make ("GET", "/api/users/{id}", agent dummy_handler)

			assert ("matches_with_id", l_route.matches ("GET", "/api/users/123"))
			assert ("matches_with_string_id", l_route.matches ("GET", "/api/users/abc"))
			assert ("no_match_extra_segment", not l_route.matches ("GET", "/api/users/123/posts"))
			assert ("no_match_missing_segment", not l_route.matches ("GET", "/api/users"))
		end

	test_multiple_parameters
			-- Test multiple path parameters
		note
			testing: "covers/{SIMPLE_WEB_SERVER_ROUTE}.matches"
		local
			l_route: SIMPLE_WEB_SERVER_ROUTE
		do
			create l_route.make ("GET", "/api/users/{user_id}/posts/{post_id}", agent dummy_handler)

			assert ("matches_both_params", l_route.matches ("GET", "/api/users/123/posts/456"))
			assert ("no_match_missing_param", not l_route.matches ("GET", "/api/users/123/posts"))
		end

	test_extract_single_parameter
			-- Test extracting a single path parameter
		note
			testing: "covers/{SIMPLE_WEB_SERVER_ROUTE}.extract_path_parameters"
		local
			l_route: SIMPLE_WEB_SERVER_ROUTE
			l_params: HASH_TABLE [STRING_32, STRING_32]
		do
			create l_route.make ("GET", "/api/users/{id}", agent dummy_handler)
			l_params := l_route.extract_path_parameters ("/api/users/123")

			assert ("has_id_param", l_params.has ("id"))
			assert ("id_value_correct", attached l_params.item ("id") as al_id and then al_id.same_string ("123"))
		end

	test_extract_multiple_parameters
			-- Test extracting multiple path parameters
		note
			testing: "covers/{SIMPLE_WEB_SERVER_ROUTE}.extract_path_parameters"
		local
			l_route: SIMPLE_WEB_SERVER_ROUTE
			l_params: HASH_TABLE [STRING_32, STRING_32]
		do
			create l_route.make ("GET", "/api/users/{user_id}/posts/{post_id}", agent dummy_handler)
			l_params := l_route.extract_path_parameters ("/api/users/42/posts/99")

			assert ("has_user_id", l_params.has ("user_id"))
			assert ("user_id_correct", attached l_params.item ("user_id") as al_uid and then al_uid.same_string ("42"))
			assert ("has_post_id", l_params.has ("post_id"))
			assert ("post_id_correct", attached l_params.item ("post_id") as al_pid and then al_pid.same_string ("99"))
		end

	test_root_path
			-- Test root path matching
		note
			testing: "covers/{SIMPLE_WEB_SERVER_ROUTE}.matches"
		local
			l_route: SIMPLE_WEB_SERVER_ROUTE
		do
			create l_route.make ("GET", "/", agent dummy_handler)

			assert ("matches_root", l_route.matches ("GET", "/"))
			assert ("no_match_non_root", not l_route.matches ("GET", "/api"))
		end

	test_method_case_insensitive
			-- Test that method matching is case insensitive
		note
			testing: "covers/{SIMPLE_WEB_SERVER_ROUTE}.matches"
		local
			l_route: SIMPLE_WEB_SERVER_ROUTE
		do
			create l_route.make ("GET", "/api/users", agent dummy_handler)

			assert ("matches_uppercase", l_route.matches ("GET", "/api/users"))
			assert ("matches_lowercase", l_route.matches ("get", "/api/users"))
			assert ("matches_mixed", l_route.matches ("Get", "/api/users"))
		end

	test_trailing_slash_handling
			-- Test handling of trailing slashes
		note
			testing: "covers/{SIMPLE_WEB_SERVER_ROUTE}.matches"
		local
			l_route: SIMPLE_WEB_SERVER_ROUTE
		do
			create l_route.make ("GET", "/api/users", agent dummy_handler)

			assert ("matches_without_trailing", l_route.matches ("GET", "/api/users"))
			assert ("matches_with_trailing", l_route.matches ("GET", "/api/users/"))
		end

feature {NONE} -- Implementation

	dummy_handler (a_request: SIMPLE_WEB_SERVER_REQUEST; a_response: SIMPLE_WEB_SERVER_RESPONSE)
			-- Dummy handler for route creation
		do
			-- No-op
		end

note
	copyright: "Copyright (c) 2024-2025, Larry Rix"
	license: "MIT License"

end
