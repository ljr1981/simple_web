note
	description: "[
		Simple request wrapper for HTTP server requests.
		Provides clean API for accessing request data.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_WEB_SERVER_REQUEST

create
	make,
	make_mock

feature {NONE} -- Initialization

	make (a_wsf_request: WSF_REQUEST)
			-- Initialize with underlying WSF request.
		require
			request_attached: a_wsf_request /= Void
		do
			wsf_request := a_wsf_request
			create path_parameters.make (5)
			create mock_headers.make (5)
			create mock_body.make_empty
			is_mock := False
		ensure
			wsf_request_set: wsf_request = a_wsf_request
			not_mock: not is_mock
		end

	make_mock (a_method: STRING; a_path: STRING_32)
			-- Create mock request for testing (no underlying WSF request).
		require
			method_attached: a_method /= Void
			path_attached: a_path /= Void
		do
			mock_method := a_method
			mock_path := a_path
			create path_parameters.make (5)
			create mock_headers.make (5)
			create mock_body.make_empty
			is_mock := True
		ensure
			is_mock: is_mock
			method_set: mock_method ~ a_method
			path_set: mock_path ~ a_path
		end

feature -- Access

	wsf_request: detachable WSF_REQUEST
			-- Underlying WSF request (Void in mock mode).

	is_mock: BOOLEAN
			-- Is this a mock request for testing?

	mock_method: detachable STRING
			-- Mock HTTP method (for testing).

	mock_path: detachable STRING_32
			-- Mock path (for testing).

	mock_headers: HASH_TABLE [STRING_8, STRING_8]
			-- Mock headers (for testing).

	mock_body: STRING_8
			-- Mock body content (for testing).

	method: STRING
			-- HTTP method (GET, POST, PUT, DELETE, etc.).
		do
			if is_mock and attached mock_method as l_method then
				Result := l_method
			elseif attached wsf_request as l_request then
				Result := l_request.request_method
			else
				create Result.make_empty
			end
		ensure
			result_attached: Result /= Void
		end

	path: STRING_32
			-- Request path (e.g., "/api/users/123").
		do
			if is_mock and attached mock_path as l_path then
				Result := l_path
			elseif attached wsf_request as l_request then
				Result := l_request.path_info
			else
				create Result.make_empty
			end
		ensure
			result_attached: Result /= Void
		end

	path_parameters: HASH_TABLE [STRING_32, STRING_32]
			-- Path parameters extracted from URL pattern.
			-- E.g., for pattern "/users/{id}" and path "/users/123", contains ["id" -> "123"].

feature -- Query Parameters

	query_parameter (a_name: READABLE_STRING_GENERAL): detachable STRING_32
			-- Get query parameter value by name (raw, unsanitized).
			-- Returns Void if not found.
			-- For sanitized access, use `safe_query_parameter'.
		require
			name_attached: a_name /= Void
		do
			if not is_mock and attached wsf_request as l_request then
				if attached l_request.query_parameter (a_name) as l_param then
					Result := l_param.string_representation.to_string_32
				end
			end
			-- Note: Mock mode doesn't support query parameters currently
		end

	safe_query_parameter (a_name: READABLE_STRING_GENERAL; a_max_length: INTEGER): detachable STRING_32
			-- Get sanitized query parameter value by name.
			-- HTML escapes and truncates to `a_max_length'.
			-- Returns Void if not found.
		require
			name_attached: a_name /= Void
			positive_length: a_max_length > 0
		do
			if attached query_parameter (a_name) as l_raw then
				Result := sanitizer.sanitize_user_input (l_raw, a_max_length)
			end
		ensure
			length_limited: attached Result implies Result.count <= a_max_length + 20
		end

	has_query_parameter (a_name: READABLE_STRING_GENERAL): BOOLEAN
			-- Does query parameter `a_name' exist?
		require
			name_attached: a_name /= Void
		do
			if not is_mock and attached wsf_request as l_request then
				Result := l_request.query_parameter (a_name) /= Void
			end
		end

feature -- Path Parameters

	path_parameter (a_name: READABLE_STRING_GENERAL): detachable STRING_32
			-- Get path parameter value by name (raw, unsanitized).
			-- Returns Void if not found.
			-- For sanitized access, use `safe_path_parameter'.
		require
			name_attached: a_name /= Void
		do
			Result := path_parameters.item (a_name.to_string_32)
		end

	safe_path_parameter (a_name: READABLE_STRING_GENERAL): detachable STRING_32
			-- Get sanitized path parameter value by name.
			-- Removes path traversal characters (.. / \).
			-- Returns Void if not found.
		require
			name_attached: a_name /= Void
		do
			if attached path_parameter (a_name) as l_raw then
				Result := sanitizer.sanitize_path_parameter (l_raw)
			end
		ensure
			sanitized: attached Result implies sanitizer.is_safe_path_parameter (Result)
		end

	has_path_parameter (a_name: READABLE_STRING_GENERAL): BOOLEAN
			-- Does path parameter `a_name' exist?
		require
			name_attached: a_name /= Void
		do
			Result := path_parameters.has (a_name.to_string_32)
		ensure
			definition: Result = path_parameters.has (a_name.to_string_32)
		end

feature -- Headers

	header (a_name: READABLE_STRING_GENERAL): detachable STRING_8
			-- Get header value by name (case-insensitive).
			-- Returns Void if not found.
		require
			name_attached: a_name /= Void
		local
			l_header_name: STRING_8
		do
			if is_mock then
				Result := mock_headers.item (a_name.to_string_32.as_upper.to_string_8)
			elseif attached wsf_request as l_request then
				l_header_name := "HTTP_" + a_name.to_string_32.as_upper.to_string_8
				if attached l_request.meta_string_variable (l_header_name) as l_value then
					Result := l_value.to_string_8
				end
			end
		end

	content_type: detachable STRING_8
			-- Content-Type header value.
		do
			if is_mock then
				Result := mock_headers.item ("CONTENT-TYPE")
			elseif attached wsf_request as l_request then
				if attached l_request.content_type as l_ct then
					Result := l_ct.string.to_string_8
				end
			end
		end

	content_length: NATURAL_64
			-- Content-Length header value.
		do
			if is_mock then
				Result := mock_body.count.to_natural_64
			elseif attached wsf_request as l_request then
				Result := l_request.content_length_value
			end
		end

feature -- Body

	body: STRING_8
			-- Request body as string (cached after first read).
		local
			l_length: INTEGER
		do
			if attached cached_body as l_cached then
				Result := l_cached
			elseif is_mock then
				Result := mock_body
				cached_body := Result
			elseif attached wsf_request as l_request then
				l_length := content_length.to_integer_32.max (0)
				if l_length > 0 and then not l_request.input.end_of_input then
					l_request.input.read_string (l_length)
					Result := l_request.input.last_string
				else
					create Result.make_empty
				end
				cached_body := Result
			else
				create Result.make_empty
				cached_body := Result
			end
		ensure
			result_attached: Result /= Void
			cached: cached_body /= Void
		end

	cached_body: detachable STRING_8
			-- Cached body content (stream can only be read once).

	body_as_json: detachable SIMPLE_JSON_OBJECT
			-- Parse body as JSON object.
			-- Returns Void if body is not valid JSON object.
		local
			l_json: SIMPLE_JSON
			l_body: STRING_8
		do
			l_body := body
			if not l_body.is_empty then
				create l_json
				if attached l_json.decode_payload (l_body) as l_value and then l_value.is_object then
					Result := l_value.as_object
				end
			end
		end

	form_data: HASH_TABLE [STRING_32, STRING_32]
			-- Parse URL-encoded form body into key-value pairs.
			-- Handles application/x-www-form-urlencoded format.
		local
			l_body: STRING_8
			l_pairs: LIST [STRING_8]
			l_parts: LIST [STRING_8]
			l_key, l_value: STRING_32
		do
			create Result.make (10)
			l_body := body
			if not l_body.is_empty then
				l_pairs := l_body.split ('&')
				across l_pairs as al_pair loop
					l_parts := al_pair.split ('=')
					if l_parts.count >= 1 then
						l_key := url_decode (l_parts.first)
						if l_parts.count >= 2 then
							l_value := url_decode (l_parts.i_th (2))
						else
							create l_value.make_empty
						end
						Result.force (l_value, l_key)
					end
				end
			end
		ensure
			result_attached: Result /= Void
		end

	form_parameter (a_name: READABLE_STRING_GENERAL): detachable STRING_32
			-- Get form parameter value by name.
			-- Returns Void if not found.
		require
			name_attached: a_name /= Void
		do
			Result := form_data.item (a_name.to_string_32)
		end

feature -- Status

	is_get: BOOLEAN
			-- Is this a GET request?
		do
			Result := method.is_case_insensitive_equal ("GET")
		ensure
			definition: Result = method.is_case_insensitive_equal ("GET")
		end

	is_post: BOOLEAN
			-- Is this a POST request?
		do
			Result := method.is_case_insensitive_equal ("POST")
		ensure
			definition: Result = method.is_case_insensitive_equal ("POST")
		end

	is_put: BOOLEAN
			-- Is this a PUT request?
		do
			Result := method.is_case_insensitive_equal ("PUT")
		ensure
			definition: Result = method.is_case_insensitive_equal ("PUT")
		end

	is_delete: BOOLEAN
			-- Is this a DELETE request?
		do
			Result := method.is_case_insensitive_equal ("DELETE")
		ensure
			definition: Result = method.is_case_insensitive_equal ("DELETE")
		end

	is_patch: BOOLEAN
			-- Is this a PATCH request?
		do
			Result := method.is_case_insensitive_equal ("PATCH")
		ensure
			definition: Result = method.is_case_insensitive_equal ("PATCH")
		end

feature {SIMPLE_WEB_SERVER_EXECUTION} -- Internal

	set_path_parameter (a_name, a_value: STRING_32)
			-- Set path parameter.
		require
			name_attached: a_name /= Void
			value_attached: a_value /= Void
		do
			path_parameters.force (a_value, a_name)
		ensure
			parameter_set: path_parameters.item (a_name) = a_value
		end

feature -- Mock Helpers

	set_mock_header (a_name: STRING_8; a_value: STRING_8)
			-- Set mock header for testing.
		require
			is_mock: is_mock
			name_attached: a_name /= Void
			value_attached: a_value /= Void
		do
			mock_headers.force (a_value, a_name.as_upper)
		ensure
			header_set: mock_headers.has (a_name.as_upper)
		end

	set_mock_body (a_body: STRING_8)
			-- Set mock body for testing.
		require
			is_mock: is_mock
			body_attached: a_body /= Void
		do
			mock_body := a_body
		ensure
			body_set: mock_body = a_body
		end

feature {NONE} -- Implementation

	sanitizer: SIMPLE_WEB_SANITIZER
			-- Shared sanitizer instance.
		once
			create Result
		ensure
			result_attached: Result /= Void
		end

	url_decode (a_encoded: STRING_8): STRING_32
			-- Decode URL-encoded string (handles %XX and + for space).
		local
			i: INTEGER
			l_code: INTEGER
			l_hex: STRING_8
		do
			create Result.make (a_encoded.count)
			from i := 1 until i > a_encoded.count loop
				if a_encoded.item (i) = '%%' and then i + 2 <= a_encoded.count then
					l_hex := a_encoded.substring (i + 1, i + 2)
					if l_hex.count = 2 and then l_hex.item (1).is_hexa_digit and then l_hex.item (2).is_hexa_digit then
						l_code := hex_to_integer (l_hex)
						Result.append_character (l_code.to_character_32)
						i := i + 3
					else
						Result.append_character ('%%')
						i := i + 1
					end
				elseif a_encoded.item (i) = '+' then
					Result.append_character (' ')
					i := i + 1
				else
					Result.append_character (a_encoded.item (i))
					i := i + 1
				end
			end
		ensure
			result_attached: Result /= Void
		end

	hex_to_integer (a_hex: STRING_8): INTEGER
			-- Convert 2-character hex string to integer.
		require
			valid_hex: a_hex.count = 2
		local
			l_high, l_low: INTEGER
		do
			l_high := hex_digit_value (a_hex.item (1))
			l_low := hex_digit_value (a_hex.item (2))
			Result := l_high * 16 + l_low
		end

	hex_digit_value (c: CHARACTER): INTEGER
			-- Value of hex digit character.
		do
			inspect c
			when '0'..'9' then Result := c.code - ('0').code
			when 'a'..'f' then Result := c.code - ('a').code + 10
			when 'A'..'F' then Result := c.code - ('A').code + 10
			else Result := 0
			end
		end

invariant
	wsf_request_attached_or_mock: is_mock or wsf_request /= Void
	path_parameters_attached: path_parameters /= Void
	mock_headers_attached: mock_headers /= Void

note
	copyright: "Copyright (c) 2024-2025, Larry Rix"
	license: "MIT License"

end
