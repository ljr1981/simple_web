note
	description: "[
		High-level wrapper for HTTP responses.
		Provides clean access to status, headers, and body content.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_WEB_RESPONSE

inherit
	SIMPLE_WEB_CONSTANTS

create
	make,
	make_with_body

feature {NONE} -- Initialization

	make (a_status_code: INTEGER)
			-- Initialize with status code
		require
			valid_status: a_status_code > 0
		do
			status_code := a_status_code
			create body.make_empty
			create headers.make (10)
		ensure
			status_set: status_code = a_status_code
			body_empty: body.is_empty
			headers_attached: headers /= Void
		end

	make_with_body (a_status_code: INTEGER; a_body: STRING)
			-- Initialize with status code and body
		require
			valid_status: a_status_code >= 0
			body_attached: a_body /= Void
		do
			make (a_status_code)
			body := a_body
		ensure
			status_set: status_code = a_status_code
			body_set: body ~ a_body
		end

feature -- Access

	status_code: INTEGER
			-- HTTP status code

	body: STRING
			-- Response body content

	headers: STRING_TABLE [STRING]
			-- Response headers (name -> value)

feature -- Status Report

	is_success: BOOLEAN
			-- Is response successful (2xx status)?
		do
			Result := status_code >= 200 and status_code < 300
		ensure
			definition: Result = (status_code >= 200 and status_code < 300)
		end

	is_ok: BOOLEAN
			-- Is status 200 OK?
		do
			Result := status_code = Status_ok
		ensure
			definition: Result = (status_code = 200)
		end

	is_client_error: BOOLEAN
			-- Is client error (4xx status)?
		do
			Result := status_code >= 400 and status_code < 500
		ensure
			definition: Result = (status_code >= 400 and status_code < 500)
		end

	is_server_error: BOOLEAN
			-- Is server error (5xx status)?
		do
			Result := status_code >= 500 and status_code < 600
		ensure
			definition: Result = (status_code >= 500 and status_code < 600)
		end

	is_error: BOOLEAN
			-- Is this an error response (4xx or 5xx)?
		do
			Result := is_client_error or is_server_error
		ensure
			definition: Result = (is_client_error or is_server_error)
		end

	error_message: detachable STRING
			-- Extract error message from JSON body if present.
			-- Looks for {"error": "message"} pattern.
		do
			if attached body_as_json as l_json and then l_json.is_object then
				if attached l_json.as_object as l_obj and then l_obj.has_key ("error") then
					if attached l_obj.string_item ("error") as l_msg then
						Result := l_msg.to_string_8
					end
				end
			end
		end

	has_header (a_name: STRING): BOOLEAN
			-- Does response have header with given name?
		require
			name_attached: a_name /= Void
		do
			from
				headers.start
				Result := false
			until
				headers.off
			loop
				if attached headers.key_for_iteration as al_header then
					Result := Result or al_header.has_substring (a_name.as_lower)
				end
				headers.forth
			end
		end

feature -- Element Change

	set_body (a_body: STRING)
			-- Set response body
		require
			body_attached: a_body /= Void
		do
			body := a_body
		ensure
			body_set: body = a_body
		end

	add_header (a_name, a_value: STRING)
			-- Add header to response
		require
			name_attached: a_name /= Void
			name_not_empty: not a_name.is_empty
			value_attached: a_value /= Void
		do
			headers.force (a_value, a_name.as_lower)
		ensure
			header_added: has_header (a_name)
		end

	header (a_name: STRING): detachable STRING
			-- Get header value by name
		require
			name_attached: a_name /= Void
		do
			if headers.has (a_name.as_lower) then
				Result := headers.item (a_name.as_lower)
			end
		end

feature -- Conversion

	body_as_json: detachable SIMPLE_JSON_VALUE
			-- Parse body as JSON
		local
			l_parser: SIMPLE_JSON
		do
			if not body.is_empty then
				create l_parser
				Result := l_parser.decode_payload (body)
			end
		end

invariant
	status_positive: status_code > 0
	body_attached: body /= Void
	headers_attached: headers /= Void

note
	copyright: "Copyright (c) 2024-2025, Larry Rix"
	license: "MIT License"
	source: "[
		SIMPLE_WEB - High-level Web API Library
		https://github.com/ljr1981/simple_web
	]"

end
