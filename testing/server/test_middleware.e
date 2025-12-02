note
	description: "Tests for middleware pipeline and built-in middleware."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_MIDDLEWARE

inherit
	TEST_SET_BASE
		redefine
			on_prepare
		end

feature {NONE} -- Setup

	on_prepare
			-- Reset router before each test.
		do
			router.clear_routes
			router.clear_middleware
			handler_executed := False
			order_list.wipe_out
		end

feature -- Pipeline Tests

	test_empty_pipeline_runs_handler
			-- Empty pipeline should run handler directly.
		local
			l_pipeline: SIMPLE_WEB_MIDDLEWARE_PIPELINE
		do
			create l_pipeline.make
			assert ("pipeline empty", l_pipeline.is_empty)

			handler_executed := False
			l_pipeline.execute (mock_request, mock_response, agent mark_handler_executed)

			assert ("handler executed", handler_executed)
		end

	test_single_middleware_runs
			-- Single middleware should process and call next.
		local
			l_pipeline: SIMPLE_WEB_MIDDLEWARE_PIPELINE
			l_middleware: TEST_COUNTING_MIDDLEWARE
		do
			create l_pipeline.make
			create l_middleware.make

			handler_executed := False
			l_pipeline.use (l_middleware)
			l_pipeline.execute (mock_request, mock_response, agent mark_handler_executed)

			assert ("middleware ran", l_middleware.call_count = 1)
			assert ("handler ran", handler_executed)
		end

	test_middleware_chain_order
			-- Middleware should run in registration order.
		local
			l_pipeline: SIMPLE_WEB_MIDDLEWARE_PIPELINE
			l_first: TEST_ORDER_MIDDLEWARE
			l_second: TEST_ORDER_MIDDLEWARE
		do
			create l_pipeline.make
			create l_first.make ("first", order_list)
			create l_second.make ("second", order_list)

			l_pipeline.use (l_first)
			l_pipeline.use (l_second)
			l_pipeline.execute (mock_request, mock_response, agent add_handler_to_order_list)

			assert ("three items", order_list.count = 3)
			assert ("first ran first", order_list [1] ~ "first")
			assert ("second ran second", order_list [2] ~ "second")
			assert ("handler ran last", order_list [3] ~ "handler")
		end

	test_middleware_can_short_circuit
			-- Middleware can stop chain by not calling next.
		local
			l_pipeline: SIMPLE_WEB_MIDDLEWARE_PIPELINE
			l_blocker: TEST_BLOCKING_MIDDLEWARE
		do
			create l_pipeline.make
			create l_blocker.make

			handler_executed := False
			l_pipeline.use (l_blocker)
			l_pipeline.execute (mock_request, mock_response, agent mark_handler_executed)

			assert ("blocker ran", l_blocker.did_block)
			assert ("handler NOT ran", not handler_executed)
		end

feature -- Logging Middleware Tests

	test_logging_middleware_name
			-- Logging middleware has correct name.
		local
			l_middleware: SIMPLE_WEB_LOGGING_MIDDLEWARE
		do
			create l_middleware.make
			assert_strings_equal ("name", "logging", l_middleware.name)
		end

	test_logging_middleware_continues_chain
			-- Logging middleware should call next.
		local
			l_middleware: SIMPLE_WEB_LOGGING_MIDDLEWARE
		do
			create l_middleware.make
			handler_executed := False
			l_middleware.process (mock_request, mock_response, agent mark_handler_executed)
			assert ("next called", handler_executed)
		end

feature -- CORS Middleware Tests

	test_cors_middleware_name
			-- CORS middleware has correct name.
		local
			l_middleware: SIMPLE_WEB_CORS_MIDDLEWARE
		do
			create l_middleware.make
			assert_strings_equal ("name", "cors", l_middleware.name)
		end

	test_cors_allow_all_by_default
			-- Default CORS allows all origins.
		local
			l_middleware: SIMPLE_WEB_CORS_MIDDLEWARE
		do
			create l_middleware.make
			assert ("allows all", l_middleware.allow_all_origins)
		end

	test_cors_specific_origin
			-- CORS can be configured for specific origin.
		local
			l_middleware: SIMPLE_WEB_CORS_MIDDLEWARE
		do
			create l_middleware.make_with_origin ("https://example.com")
			assert ("not allow all", not l_middleware.allow_all_origins)
			assert ("has origin", has_origin (l_middleware.allowed_origins, "https://example.com"))
		end

	test_cors_multiple_origins
			-- CORS can be configured for multiple origins.
		local
			l_middleware: SIMPLE_WEB_CORS_MIDDLEWARE
		do
			create l_middleware.make_with_origins (<<"https://a.com", "https://b.com">>)
			assert ("not allow all", not l_middleware.allow_all_origins)
			assert ("has a", has_origin (l_middleware.allowed_origins, "https://a.com"))
			assert ("has b", has_origin (l_middleware.allowed_origins, "https://b.com"))
		end

feature -- Auth Middleware Tests

	test_auth_middleware_name
			-- Auth middleware has correct name.
		local
			l_middleware: SIMPLE_WEB_AUTH_MIDDLEWARE
		do
			create l_middleware.make_bearer (agent valid_token)
			assert_strings_equal ("name", "auth", l_middleware.name)
		end

	test_auth_can_exclude_paths
			-- Auth can exclude paths from checking.
		local
			l_middleware: SIMPLE_WEB_AUTH_MIDDLEWARE
		do
			create l_middleware.make_bearer (agent valid_token)
			l_middleware.exclude_path ("/health")
			l_middleware.exclude_path ("/login")
			assert ("has exclusions", attached l_middleware.excluded_paths as l_excl and then l_excl.count = 2)
		end

feature {NONE} -- Test Helpers

	handler_executed: BOOLEAN
			-- Flag to track if handler was executed.

	mark_handler_executed
			-- Agent to mark handler as executed.
		do
			handler_executed := True
		end

	add_handler_to_order_list
			-- Agent to add "handler" to order list.
		do
			order_list.extend ("handler")
		end

	router: SIMPLE_WEB_SERVER_ROUTER
			-- Shared router for tests.
		once
			create Result
		end

	mock_request: SIMPLE_WEB_SERVER_REQUEST
			-- Create mock request for testing.
		do
			create Result.make_mock ("GET", "/test")
		end

	mock_response: SIMPLE_WEB_SERVER_RESPONSE
			-- Create mock response for testing.
		do
			create Result.make_mock
		end

	order_list: ARRAYED_LIST [STRING]
			-- Track execution order.
		once
			create Result.make (5)
		end

	valid_token (a_token: STRING): BOOLEAN
			-- Mock token validator.
		do
			Result := a_token ~ "valid-token"
		end

	has_origin (a_list: ARRAYED_LIST [STRING]; a_origin: STRING): BOOLEAN
			-- Does list contain origin (using value equality)?
		do
			Result := across a_list as ic some ic ~ a_origin end
		end

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
