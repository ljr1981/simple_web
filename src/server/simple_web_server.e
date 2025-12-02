note
	description: "[
		Simple HTTP server with clean routing API.

		Example usage:
			create server.make (8080)
			server.on_get ("/", agent handle_root)
			server.on_get ("/api/users", agent handle_users)
			server.on_get ("/api/users/{id}", agent handle_user)
			server.on_post ("/api/users", agent create_user)
			server.start
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_WEB_SERVER

inherit
	WSF_DEFAULT_SERVICE [SIMPLE_WEB_SERVER_EXECUTION]
		redefine
			initialize
		end

create
	make

feature {NONE} -- Initialization

	make (a_port: INTEGER)
			-- Create server listening on `a_port'.
		require
			valid_port: a_port > 0 and a_port < 65536
		do
			port := a_port
			initialize
			set_service_option ("port", a_port)
		ensure
			port_set: port = a_port
		end

	initialize
			-- Initialize server options.
		do
			Precursor
		end

feature -- Access

	port: INTEGER
			-- Port number server listens on.

feature -- Route Registration

	on_get (a_pattern: STRING; a_handler: PROCEDURE [SIMPLE_WEB_SERVER_REQUEST, SIMPLE_WEB_SERVER_RESPONSE])
			-- Register GET handler for `a_pattern'.
		require
			pattern_attached: a_pattern /= Void
			handler_attached: a_handler /= Void
		do
			add_route ("GET", a_pattern, a_handler)
		end

	on_post (a_pattern: STRING; a_handler: PROCEDURE [SIMPLE_WEB_SERVER_REQUEST, SIMPLE_WEB_SERVER_RESPONSE])
			-- Register POST handler for `a_pattern'.
		require
			pattern_attached: a_pattern /= Void
			handler_attached: a_handler /= Void
		do
			add_route ("POST", a_pattern, a_handler)
		end

	on_put (a_pattern: STRING; a_handler: PROCEDURE [SIMPLE_WEB_SERVER_REQUEST, SIMPLE_WEB_SERVER_RESPONSE])
			-- Register PUT handler for `a_pattern'.
		require
			pattern_attached: a_pattern /= Void
			handler_attached: a_handler /= Void
		do
			add_route ("PUT", a_pattern, a_handler)
		end

	on_delete (a_pattern: STRING; a_handler: PROCEDURE [SIMPLE_WEB_SERVER_REQUEST, SIMPLE_WEB_SERVER_RESPONSE])
			-- Register DELETE handler for `a_pattern'.
		require
			pattern_attached: a_pattern /= Void
			handler_attached: a_handler /= Void
		do
			add_route ("DELETE", a_pattern, a_handler)
		end

	on_patch (a_pattern: STRING; a_handler: PROCEDURE [SIMPLE_WEB_SERVER_REQUEST, SIMPLE_WEB_SERVER_RESPONSE])
			-- Register PATCH handler for `a_pattern'.
		require
			pattern_attached: a_pattern /= Void
			handler_attached: a_handler /= Void
		do
			add_route ("PATCH", a_pattern, a_handler)
		end

	on (a_method, a_pattern: STRING; a_handler: PROCEDURE [SIMPLE_WEB_SERVER_REQUEST, SIMPLE_WEB_SERVER_RESPONSE])
			-- Register handler for any HTTP method.
		require
			method_attached: a_method /= Void
			pattern_attached: a_pattern /= Void
			handler_attached: a_handler /= Void
		do
			add_route (a_method, a_pattern, a_handler)
		end

feature -- Server Control

	start
			-- Start the server (blocking).
		do
			print ("Starting server on port " + port.out + "...%N")
			launch (service_options)
		end

	set_verbose (a_verbose: BOOLEAN)
			-- Set verbose mode for debugging.
		do
			set_service_option ("verbose", a_verbose)
		end

feature {NONE} -- Implementation

	router: SIMPLE_WEB_SERVER_ROUTER
			-- Shared router singleton (same instance used by execution).
		once
			create Result
		ensure
			result_attached: Result /= Void
		end

	add_route (a_method, a_pattern: STRING; a_handler: PROCEDURE [SIMPLE_WEB_SERVER_REQUEST, SIMPLE_WEB_SERVER_RESPONSE])
			-- Add route to router.
		require
			method_attached: a_method /= Void
			pattern_attached: a_pattern /= Void
			handler_attached: a_handler /= Void
		local
			l_route: SIMPLE_WEB_SERVER_ROUTE
		do
			create l_route.make (a_method, a_pattern, a_handler)
			router.add_route (l_route)
		end

invariant
	port_valid: port > 0 and port < 65536

note
	copyright: "Copyright (c) 2024-2025, Larry Rix"
	license: "MIT License"

end
