note
	description: "Tests for {SIMPLE_WEB_SERVER_ROUTER}"
	testing: "type/manual"

class
	TEST_SIMPLE_WEB_SERVER_ROUTER

inherit
	TEST_SET_BASE

feature -- Test routines

	test_add_route
			-- Test adding routes to router
		note
			testing: "covers/{SIMPLE_WEB_SERVER_ROUTER}.add_route"
		local
			l_router: SIMPLE_WEB_SERVER_ROUTER
			l_route: SIMPLE_WEB_SERVER_ROUTE
		do
			create l_router
			l_router.clear_routes -- Clear any existing routes from singleton
			create l_route.make ("GET", "/api/users", agent dummy_handler)
			l_router.add_route (l_route)

			assert ("route_added", l_router.routes.has (l_route))
			assert ("route_count", l_router.routes.count = 1)
		end

	test_find_exact_route
			-- Test finding an exact matching route
		note
			testing: "covers/{SIMPLE_WEB_SERVER_ROUTER}.find_route"
		local
			l_router: SIMPLE_WEB_SERVER_ROUTER
			l_route1, l_route2: SIMPLE_WEB_SERVER_ROUTE
			l_found: detachable SIMPLE_WEB_SERVER_ROUTE
		do
			create l_router
			l_router.clear_routes
			create l_route1.make ("GET", "/api/users", agent dummy_handler)
			create l_route2.make ("POST", "/api/users", agent dummy_handler)
			l_router.add_route (l_route1)
			l_router.add_route (l_route2)

			l_found := l_router.find_route ("GET", "/api/users")
			assert ("found_get_route", l_found = l_route1)

			l_found := l_router.find_route ("POST", "/api/users")
			assert ("found_post_route", l_found = l_route2)
		end

	test_find_parameterized_route
			-- Test finding a route with path parameters
		note
			testing: "covers/{SIMPLE_WEB_SERVER_ROUTER}.find_route"
		local
			l_router: SIMPLE_WEB_SERVER_ROUTER
			l_route: SIMPLE_WEB_SERVER_ROUTE
			l_found: detachable SIMPLE_WEB_SERVER_ROUTE
		do
			create l_router
			l_router.clear_routes
			create l_route.make ("GET", "/api/users/{id}", agent dummy_handler)
			l_router.add_route (l_route)

			l_found := l_router.find_route ("GET", "/api/users/123")
			assert ("found_parameterized_route", l_found = l_route)
		end

	test_find_no_match
			-- Test that non-matching routes return Void
		note
			testing: "covers/{SIMPLE_WEB_SERVER_ROUTER}.find_route"
		local
			l_router: SIMPLE_WEB_SERVER_ROUTER
			l_route: SIMPLE_WEB_SERVER_ROUTE
			l_found: detachable SIMPLE_WEB_SERVER_ROUTE
		do
			create l_router
			l_router.clear_routes
			create l_route.make ("GET", "/api/users", agent dummy_handler)
			l_router.add_route (l_route)

			l_found := l_router.find_route ("GET", "/api/posts")
			assert ("no_match_returns_void", l_found = Void)
		end

	test_route_priority
			-- Test that routes are matched in order of registration
		note
			testing: "covers/{SIMPLE_WEB_SERVER_ROUTER}.find_route"
		local
			l_router: SIMPLE_WEB_SERVER_ROUTER
			l_route1, l_route2: SIMPLE_WEB_SERVER_ROUTE
			l_found: detachable SIMPLE_WEB_SERVER_ROUTE
		do
			create l_router
			l_router.clear_routes
			-- More specific route first
			create l_route1.make ("GET", "/api/users/me", agent dummy_handler)
			-- Generic parameterized route second
			create l_route2.make ("GET", "/api/users/{id}", agent dummy_handler)
			l_router.add_route (l_route1)
			l_router.add_route (l_route2)

			-- "me" should match the specific route, not the parameter
			l_found := l_router.find_route ("GET", "/api/users/me")
			assert ("specific_route_matched", l_found = l_route1)

			-- Other values match the parameterized route
			l_found := l_router.find_route ("GET", "/api/users/123")
			assert ("param_route_matched", l_found = l_route2)
		end

	test_clear_routes
			-- Test clearing all routes
		note
			testing: "covers/{SIMPLE_WEB_SERVER_ROUTER}.clear_routes"
		local
			l_router: SIMPLE_WEB_SERVER_ROUTER
			l_route: SIMPLE_WEB_SERVER_ROUTE
		do
			create l_router
			create l_route.make ("GET", "/api/users", agent dummy_handler)
			l_router.add_route (l_route)

			assert ("has_routes", not l_router.routes.is_empty)

			l_router.clear_routes

			assert ("routes_cleared", l_router.routes.is_empty)
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
