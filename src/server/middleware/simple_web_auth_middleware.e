note
	description: "[
		Authentication middleware supporting multiple auth schemes.

		Supports:
		- Bearer token (JWT or opaque tokens)
		- Basic authentication
		- API key (header or query param)

		Usage (Bearer token):
			create auth.make_bearer (agent validate_token)
			server.use_middleware (auth)

		Usage (API key):
			create auth.make_api_key ("X-API-Key", agent validate_key)
			server.use_middleware (auth)

		The validator agent receives the token/key and returns True if valid.
		If validation fails, returns 401 Unauthorized.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_WEB_AUTH_MIDDLEWARE

inherit
	SIMPLE_WEB_MIDDLEWARE

create
	make_bearer,
	make_basic,
	make_api_key

feature {NONE} -- Initialization

	make_bearer (a_validator: FUNCTION [STRING, BOOLEAN])
			-- Create Bearer token authentication.
			-- `a_validator' receives the token and returns True if valid.
		require
			validator_attached: a_validator /= Void
		do
			auth_scheme := Scheme_bearer
			token_validator := a_validator
			create api_key_header.make_empty
		ensure
			bearer_scheme: auth_scheme = Scheme_bearer
		end

	make_basic (a_validator: FUNCTION [STRING, STRING, BOOLEAN])
			-- Create Basic authentication.
			-- `a_validator' receives (username, password) and returns True if valid.
		require
			validator_attached: a_validator /= Void
		do
			auth_scheme := Scheme_basic
			basic_validator := a_validator
			create api_key_header.make_empty
		ensure
			basic_scheme: auth_scheme = Scheme_basic
		end

	make_api_key (a_header_name: STRING; a_validator: FUNCTION [STRING, BOOLEAN])
			-- Create API key authentication via header.
			-- `a_validator' receives the key and returns True if valid.
		require
			header_attached: a_header_name /= Void
			header_not_empty: not a_header_name.is_empty
			validator_attached: a_validator /= Void
		do
			auth_scheme := Scheme_api_key
			api_key_header := a_header_name
			token_validator := a_validator
		ensure
			api_key_scheme: auth_scheme = Scheme_api_key
			header_set: api_key_header = a_header_name
		end

feature -- Access

	name: STRING = "auth"
			-- Middleware name.

	auth_scheme: INTEGER
			-- Current authentication scheme.

	api_key_header: STRING
			-- Header name for API key auth.

feature -- Configuration

	excluded_paths: detachable ARRAYED_LIST [STRING]
			-- Paths that don't require authentication.

	exclude_path (a_path: STRING)
			-- Add `a_path' to exclusion list (no auth required).
		require
			path_attached: a_path /= Void
		local
			l_list: ARRAYED_LIST [STRING]
		do
			if attached excluded_paths as l_excluded then
				l_excluded.extend (a_path)
			else
				create l_list.make (5)
				l_list.extend (a_path)
				excluded_paths := l_list
			end
		end

feature -- Processing

	process (a_request: SIMPLE_WEB_SERVER_REQUEST; a_response: SIMPLE_WEB_SERVER_RESPONSE; a_next: PROCEDURE)
			-- Validate authentication, continue or return 401.
		do
			if is_path_excluded (a_request.path.to_string_8) then
				-- Path doesn't require auth
				a_next.call (Void)
			elseif validate_request (a_request) then
				-- Auth valid, continue
				a_next.call (Void)
			else
				-- Auth failed
				a_response.set_status (401)
				a_response.set_header ("WWW-Authenticate", www_authenticate_header)
				a_response.send_json ("{%"error%":%"Unauthorized%"}")
			end
		end

feature {NONE} -- Implementation

	token_validator: detachable FUNCTION [STRING, BOOLEAN]
			-- Validator for bearer/API key tokens.

	basic_validator: detachable FUNCTION [STRING, STRING, BOOLEAN]
			-- Validator for basic auth (username, password).

	is_path_excluded (a_path: STRING): BOOLEAN
			-- Is `a_path' excluded from auth?
		do
			if attached excluded_paths as l_excluded then
				Result := l_excluded.has (a_path)
			end
		end

	validate_request (a_request: SIMPLE_WEB_SERVER_REQUEST): BOOLEAN
			-- Validate authentication based on scheme.
		do
			inspect auth_scheme
			when Scheme_bearer then
				Result := validate_bearer (a_request)
			when Scheme_basic then
				Result := validate_basic (a_request)
			when Scheme_api_key then
				Result := validate_api_key (a_request)
			else
				Result := False
			end
		end

	validate_bearer (a_request: SIMPLE_WEB_SERVER_REQUEST): BOOLEAN
			-- Validate Bearer token from Authorization header.
		local
			l_auth: detachable STRING
			l_token: STRING
		do
			l_auth := a_request.header ("Authorization")
			if attached l_auth and then l_auth.starts_with ("Bearer ") then
				l_token := l_auth.substring (8, l_auth.count)
				if attached token_validator as l_validator then
					Result := l_validator.item ([l_token])
				end
			end
		end

	validate_basic (a_request: SIMPLE_WEB_SERVER_REQUEST): BOOLEAN
			-- Validate Basic auth from Authorization header.
		local
			l_auth_header: detachable STRING
			l_http_auth: HTTP_AUTHORIZATION
		do
			l_auth_header := a_request.header ("Authorization")
			if attached l_auth_header then
				create l_http_auth.make (l_auth_header)
				if l_http_auth.is_basic and then
				   attached l_http_auth.login as l_login and then
				   attached l_http_auth.password as l_password and then
				   attached basic_validator as l_validator
				then
					Result := l_validator.item ([l_login.to_string_8, l_password.to_string_8])
				end
			end
		end

	validate_api_key (a_request: SIMPLE_WEB_SERVER_REQUEST): BOOLEAN
			-- Validate API key from custom header.
		local
			l_key: detachable STRING
		do
			l_key := a_request.header (api_key_header)
			if attached l_key and then attached token_validator as l_validator then
				Result := l_validator.item ([l_key])
			end
		end

	www_authenticate_header: STRING
			-- WWW-Authenticate header value for 401 response.
		do
			inspect auth_scheme
			when Scheme_bearer then
				Result := "Bearer"
			when Scheme_basic then
				Result := "Basic realm=%"Restricted%""
			when Scheme_api_key then
				Result := "API-Key"
			else
				Result := "Unknown"
			end
		end

feature {NONE} -- Constants

	Scheme_bearer: INTEGER = 1
	Scheme_basic: INTEGER = 2
	Scheme_api_key: INTEGER = 3

invariant
	api_key_header_attached: api_key_header /= Void
	valid_scheme: auth_scheme >= 1 and auth_scheme <= 3

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
