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
			-- Get query parameter value by name.
			-- Returns Void if not found.
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
			-- Get path parameter value by name.
			-- Returns Void if not found.
		require
			name_attached: a_name /= Void
		do
			Result := path_parameters.item (a_name.to_string_32)
		end

	has_path_parameter (a_name: READABLE_STRING_GENERAL): BOOLEAN
			-- Does path parameter `a_name' exist?
		require
			name_attached: a_name /= Void
		do
			Result := path_parameters.has (a_name.to_string_32)
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
			-- Request body as string.
		local
			l_length: INTEGER
		do
			if is_mock then
				Result := mock_body
			elseif attached wsf_request as l_request then
				l_length := content_length.to_integer_32.max (0)
				if l_length > 0 and then not l_request.input.end_of_input then
					l_request.input.read_string (l_length)
					Result := l_request.input.last_string
				else
					create Result.make_empty
				end
			else
				create Result.make_empty
			end
		ensure
			result_attached: Result /= Void
		end

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
				if attached l_json.parse (l_body) as l_value and then l_value.is_object then
					Result := l_value.as_object
				end
			end
		end

feature -- Status

	is_get: BOOLEAN
			-- Is this a GET request?
		do
			Result := method.is_case_insensitive_equal ("GET")
		end

	is_post: BOOLEAN
			-- Is this a POST request?
		do
			Result := method.is_case_insensitive_equal ("POST")
		end

	is_put: BOOLEAN
			-- Is this a PUT request?
		do
			Result := method.is_case_insensitive_equal ("PUT")
		end

	is_delete: BOOLEAN
			-- Is this a DELETE request?
		do
			Result := method.is_case_insensitive_equal ("DELETE")
		end

	is_patch: BOOLEAN
			-- Is this a PATCH request?
		do
			Result := method.is_case_insensitive_equal ("PATCH")
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
		end

	set_mock_body (a_body: STRING_8)
			-- Set mock body for testing.
		require
			is_mock: is_mock
			body_attached: a_body /= Void
		do
			mock_body := a_body
		end

invariant
	wsf_request_attached_or_mock: is_mock or wsf_request /= Void
	path_parameters_attached: path_parameters /= Void
	mock_headers_attached: mock_headers /= Void

note
	copyright: "Copyright (c) 2024-2025, Larry Rix"
	license: "MIT License"

end
