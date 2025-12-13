note
	description: "Test application for SIMPLE_WEB"
	author: "Larry Rix"

class
	TEST_APP

create
	make

feature {NONE} -- Initialization

	make
			-- Run the tests.
		do
			print ("Running SIMPLE_WEB tests...%N%N")
			passed := 0
			failed := 0

			run_lib_tests
			run_middleware_tests
			run_sanitizer_tests
			run_router_tests
			run_route_tests

			print ("%N========================%N")
			print ("Results: " + passed.out + " passed, " + failed.out + " failed%N")

			if failed > 0 then
				print ("TESTS FAILED%N")
			else
				print ("ALL TESTS PASSED%N")
			end
		end

feature {NONE} -- Test Runners

	run_lib_tests
			-- Run core library tests.
		do
			print ("=== LIB_TESTS ===%N")
			create lib_tests
			-- Request creation tests
			run_test (agent lib_tests.test_make_get_request, "test_make_get_request")
			run_test (agent lib_tests.test_make_post_request, "test_make_post_request")
			run_test (agent lib_tests.test_make_put_request, "test_make_put_request")
			run_test (agent lib_tests.test_make_delete_request, "test_make_delete_request")
			-- Request header tests
			run_test (agent lib_tests.test_with_header, "test_with_header")
			run_test (agent lib_tests.test_with_json_content_type, "test_with_json_content_type")
			run_test (agent lib_tests.test_with_bearer_token, "test_with_bearer_token")
			-- Request body tests
			run_test (agent lib_tests.test_with_body, "test_with_body")
			-- Response creation tests
			run_test (agent lib_tests.test_response_make, "test_response_make")
			run_test (agent lib_tests.test_response_is_success, "test_response_is_success")
			run_test (agent lib_tests.test_response_is_client_error, "test_response_is_client_error")
			run_test (agent lib_tests.test_response_is_server_error, "test_response_is_server_error")
			-- Client tests
			run_test (agent lib_tests.test_client_make, "test_client_make")
		end

	run_middleware_tests
			-- Run middleware pipeline tests.
		do
			print ("%N=== TEST_MIDDLEWARE ===%N")
			create middleware_tests
			-- Pipeline tests
			run_test (agent middleware_tests.test_empty_pipeline_runs_handler, "test_empty_pipeline_runs_handler")
			run_test (agent middleware_tests.test_single_middleware_runs, "test_single_middleware_runs")
			run_test (agent middleware_tests.test_middleware_chain_order, "test_middleware_chain_order")
			run_test (agent middleware_tests.test_middleware_can_short_circuit, "test_middleware_can_short_circuit")
			-- Logging middleware tests
			run_test (agent middleware_tests.test_logging_middleware_name, "test_logging_middleware_name")
			run_test (agent middleware_tests.test_logging_middleware_continues_chain, "test_logging_middleware_continues_chain")
			-- CORS middleware tests
			run_test (agent middleware_tests.test_cors_middleware_name, "test_cors_middleware_name")
			run_test (agent middleware_tests.test_cors_allow_all_by_default, "test_cors_allow_all_by_default")
			run_test (agent middleware_tests.test_cors_specific_origin, "test_cors_specific_origin")
			run_test (agent middleware_tests.test_cors_multiple_origins, "test_cors_multiple_origins")
			-- Auth middleware tests
			run_test (agent middleware_tests.test_auth_middleware_name, "test_auth_middleware_name")
			run_test (agent middleware_tests.test_auth_can_exclude_paths, "test_auth_can_exclude_paths")
		end

	run_sanitizer_tests
			-- Run input sanitization tests.
		do
			print ("%N=== TEST_SANITIZER ===%N")
			create sanitizer_tests
			-- HTML sanitization
			run_test (agent sanitizer_tests.test_sanitize_html_basic, "test_sanitize_html_basic")
			run_test (agent sanitizer_tests.test_sanitize_html_script_tag, "test_sanitize_html_script_tag")
			run_test (agent sanitizer_tests.test_strip_html_tags, "test_strip_html_tags")
			-- Path parameter sanitization
			run_test (agent sanitizer_tests.test_sanitize_path_traversal, "test_sanitize_path_traversal")
			run_test (agent sanitizer_tests.test_sanitize_path_backslash, "test_sanitize_path_backslash")
			run_test (agent sanitizer_tests.test_is_safe_path_parameter, "test_is_safe_path_parameter")
			-- Header sanitization
			run_test (agent sanitizer_tests.test_sanitize_header_crlf, "test_sanitize_header_crlf")
			run_test (agent sanitizer_tests.test_is_safe_header, "test_is_safe_header")
			-- SQL sanitization
			run_test (agent sanitizer_tests.test_escape_sql_quotes, "test_escape_sql_quotes")
			-- JSON sanitization
			run_test (agent sanitizer_tests.test_sanitize_json_string, "test_sanitize_json_string")
			-- Length validation
			run_test (agent sanitizer_tests.test_truncate, "test_truncate")
			run_test (agent sanitizer_tests.test_is_within_length, "test_is_within_length")
			-- Combined sanitization
			run_test (agent sanitizer_tests.test_sanitize_user_input, "test_sanitize_user_input")
		end

	run_router_tests
			-- Run router tests.
		do
			print ("%N=== TEST_SIMPLE_WEB_SERVER_ROUTER ===%N")
			create router_tests
			run_test (agent router_tests.test_add_route, "test_add_route")
			run_test (agent router_tests.test_find_exact_route, "test_find_exact_route")
			run_test (agent router_tests.test_find_parameterized_route, "test_find_parameterized_route")
			run_test (agent router_tests.test_find_no_match, "test_find_no_match")
			run_test (agent router_tests.test_route_priority, "test_route_priority")
			run_test (agent router_tests.test_clear_routes, "test_clear_routes")
		end

	run_route_tests
			-- Run route pattern matching tests.
		do
			print ("%N=== TEST_SIMPLE_WEB_SERVER_ROUTE ===%N")
			create route_tests
			run_test (agent route_tests.test_exact_path_match, "test_exact_path_match")
			run_test (agent route_tests.test_path_with_parameter, "test_path_with_parameter")
			run_test (agent route_tests.test_multiple_parameters, "test_multiple_parameters")
			run_test (agent route_tests.test_extract_single_parameter, "test_extract_single_parameter")
			run_test (agent route_tests.test_extract_multiple_parameters, "test_extract_multiple_parameters")
			run_test (agent route_tests.test_root_path, "test_root_path")
			run_test (agent route_tests.test_method_case_insensitive, "test_method_case_insensitive")
			run_test (agent route_tests.test_trailing_slash_handling, "test_trailing_slash_handling")
		end

feature {NONE} -- Implementation

	lib_tests: LIB_TESTS
	middleware_tests: TEST_MIDDLEWARE
	sanitizer_tests: TEST_SANITIZER
	router_tests: TEST_SIMPLE_WEB_SERVER_ROUTER
	route_tests: TEST_SIMPLE_WEB_SERVER_ROUTE

	passed: INTEGER
	failed: INTEGER

	run_test (a_test: PROCEDURE; a_name: STRING)
			-- Run a single test and update counters.
		local
			l_retried: BOOLEAN
		do
			if not l_retried then
				a_test.call (Void)
				print ("  PASS: " + a_name + "%N")
				passed := passed + 1
			end
		rescue
			print ("  FAIL: " + a_name + "%N")
			failed := failed + 1
			l_retried := True
			retry
		end

end
