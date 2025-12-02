note
	description: "[
		CORS (Cross-Origin Resource Sharing) middleware.

		Handles:
		- Access-Control-Allow-Origin header
		- Preflight OPTIONS requests
		- Configurable allowed methods and headers

		Usage (allow all origins):
			server.use_middleware (create {SIMPLE_WEB_CORS_MIDDLEWARE})

		Usage (specific origins):
			create cors.make_with_origins (<<"https://example.com", "https://app.example.com">>)
			server.use_middleware (cors)
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_WEB_CORS_MIDDLEWARE

inherit
	SIMPLE_WEB_MIDDLEWARE

create
	make,
	make_with_origin,
	make_with_origins

feature {NONE} -- Initialization

	make
			-- Create allowing all origins (*).
		do
			allow_all_origins := True
			create allowed_origins.make (0)
			allowed_methods := Default_methods
			allowed_headers := Default_headers
			max_age := 86400 -- 24 hours
		ensure
			allow_all: allow_all_origins
		end

	make_with_origin (a_origin: STRING)
			-- Create allowing single `a_origin'.
		require
			origin_attached: a_origin /= Void
			origin_not_empty: not a_origin.is_empty
		do
			allow_all_origins := False
			create allowed_origins.make (1)
			allowed_origins.extend (a_origin)
			allowed_methods := Default_methods
			allowed_headers := Default_headers
			max_age := 86400
		ensure
			not_allow_all: not allow_all_origins
			has_origin: allowed_origins.has (a_origin)
		end

	make_with_origins (a_origins: ARRAY [STRING])
			-- Create allowing multiple `a_origins'.
		require
			origins_attached: a_origins /= Void
			origins_not_empty: a_origins.count > 0
		local
			i: INTEGER
		do
			allow_all_origins := False
			create allowed_origins.make (a_origins.count)
			from i := a_origins.lower until i > a_origins.upper loop
				allowed_origins.extend (a_origins [i])
				i := i + 1
			end
			allowed_methods := Default_methods
			allowed_headers := Default_headers
			max_age := 86400
		ensure
			not_allow_all: not allow_all_origins
		end

feature -- Access

	name: STRING = "cors"
			-- Middleware name.

	allow_all_origins: BOOLEAN
			-- Allow requests from any origin?

	allowed_origins: ARRAYED_LIST [STRING]
			-- List of allowed origins (if not allow_all).

	allowed_methods: STRING
			-- Comma-separated allowed HTTP methods.

	allowed_headers: STRING
			-- Comma-separated allowed headers.

	max_age: INTEGER
			-- Preflight cache duration in seconds.

feature -- Configuration

	set_allowed_methods (a_methods: STRING)
			-- Set allowed HTTP methods.
		require
			methods_attached: a_methods /= Void
		do
			allowed_methods := a_methods
		ensure
			methods_set: allowed_methods = a_methods
		end

	set_allowed_headers (a_headers: STRING)
			-- Set allowed headers.
		require
			headers_attached: a_headers /= Void
		do
			allowed_headers := a_headers
		ensure
			headers_set: allowed_headers = a_headers
		end

	set_max_age (a_seconds: INTEGER)
			-- Set preflight cache duration.
		require
			positive: a_seconds >= 0
		do
			max_age := a_seconds
		ensure
			age_set: max_age = a_seconds
		end

feature -- Processing

	process (a_request: SIMPLE_WEB_SERVER_REQUEST; a_response: SIMPLE_WEB_SERVER_RESPONSE; a_next: PROCEDURE)
			-- Add CORS headers and handle preflight.
		local
			l_origin: detachable STRING
		do
			l_origin := a_request.header ("Origin")

			if l_origin /= Void and then is_origin_allowed (l_origin) then
				-- Add CORS headers
				add_cors_headers (a_response, l_origin)

				if a_request.method.same_string ("OPTIONS") then
					-- Preflight request - respond immediately
					a_response.set_status (204) -- No Content
				else
					-- Normal request - continue chain
					a_next.call (Void)
				end
			else
				-- No Origin header or not allowed - continue without CORS headers
				a_next.call (Void)
			end
		end

feature {NONE} -- Implementation

	is_origin_allowed (a_origin: STRING): BOOLEAN
			-- Is `a_origin' in allowed list?
		do
			if allow_all_origins then
				Result := True
			else
				Result := allowed_origins.has (a_origin)
			end
		end

	add_cors_headers (a_response: SIMPLE_WEB_SERVER_RESPONSE; a_origin: STRING)
			-- Add CORS headers to response.
		do
			if allow_all_origins then
				a_response.set_header ("Access-Control-Allow-Origin", "*")
			else
				a_response.set_header ("Access-Control-Allow-Origin", a_origin)
				a_response.set_header ("Vary", "Origin")
			end
			a_response.set_header ("Access-Control-Allow-Methods", allowed_methods)
			a_response.set_header ("Access-Control-Allow-Headers", allowed_headers)
			a_response.set_header ("Access-Control-Max-Age", max_age.out)
		end

feature {NONE} -- Constants

	Default_methods: STRING = "GET, POST, PUT, DELETE, PATCH, OPTIONS"
			-- Default allowed HTTP methods.

	Default_headers: STRING = "Content-Type, Authorization, X-Requested-With"
			-- Default allowed headers.

invariant
	allowed_origins_attached: allowed_origins /= Void
	allowed_methods_attached: allowed_methods /= Void
	allowed_headers_attached: allowed_headers /= Void
	max_age_non_negative: max_age >= 0

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
