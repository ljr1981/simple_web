note
	description: "[
		Simple response wrapper for HTTP server responses.
		Provides clean API for sending responses back to clients.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_WEB_SERVER_RESPONSE

create
	make,
	make_mock

feature {NONE} -- Initialization

	make (a_wsf_response: WSF_RESPONSE)
			-- Initialize with underlying WSF response.
		require
			response_attached: a_wsf_response /= Void
		do
			wsf_response := a_wsf_response
			status_code := 200
			is_mock := False
			create mock_headers.make (10)
			create mock_body.make_empty
		ensure
			wsf_response_set: wsf_response = a_wsf_response
			default_status: status_code = 200
			not_mock: not is_mock
		end

	make_mock
			-- Create mock response for testing (no underlying WSF response).
		do
			status_code := 200
			is_mock := True
			create mock_headers.make (10)
			create mock_body.make_empty
		ensure
			is_mock: is_mock
			default_status: status_code = 200
		end

feature -- Access

	status_code: INTEGER
			-- HTTP status code to send.

	wsf_response: detachable WSF_RESPONSE
			-- Underlying WSF response (Void in mock mode).

	is_mock: BOOLEAN
			-- Is this a mock response for testing?

	mock_headers: HASH_TABLE [STRING_8, STRING_8]
			-- Headers set in mock mode (for testing verification).

	mock_body: STRING_8
			-- Body content set in mock mode (for testing verification).

feature -- Status Setting

	set_status (a_code: INTEGER)
			-- Set HTTP status code.
		require
			valid_code: a_code >= 100 and a_code < 600
		do
			status_code := a_code
		ensure
			status_set: status_code = a_code
		end

	set_ok
			-- Set status to 200 OK.
		do
			set_status (200)
		ensure
			status_ok: status_code = 200
		end

	set_created
			-- Set status to 201 Created.
		do
			set_status (201)
		ensure
			status_created: status_code = 201
		end

	set_no_content
			-- Set status to 204 No Content.
		do
			set_status (204)
		ensure
			status_no_content: status_code = 204
		end

	set_bad_request
			-- Set status to 400 Bad Request.
		do
			set_status (400)
		ensure
			status_bad_request: status_code = 400
		end

	set_unauthorized
			-- Set status to 401 Unauthorized.
		do
			set_status (401)
		ensure
			status_unauthorized: status_code = 401
		end

	set_forbidden
			-- Set status to 403 Forbidden.
		do
			set_status (403)
		ensure
			status_forbidden: status_code = 403
		end

	set_not_found
			-- Set status to 404 Not Found.
		do
			set_status (404)
		ensure
			status_not_found: status_code = 404
		end

	set_internal_server_error
			-- Set status to 500 Internal Server Error.
		do
			set_status (500)
		ensure
			status_error: status_code = 500
		end

feature -- Response Sending

	send_text (a_text: READABLE_STRING_8)
			-- Send plain text response.
		require
			text_attached: a_text /= Void
		do
			send_with_content_type (a_text, "text/plain; charset=utf-8")
		end

	send_html (a_html: READABLE_STRING_8)
			-- Send HTML response.
		require
			html_attached: a_html /= Void
		do
			send_with_content_type (a_html, "text/html; charset=utf-8")
		end

	send_json (a_json: READABLE_STRING_8)
			-- Send JSON response.
		require
			json_attached: a_json /= Void
		do
			send_with_content_type (a_json, "application/json; charset=utf-8")
		end

	send_json_object (a_object: SIMPLE_JSON_OBJECT)
			-- Send SIMPLE_JSON_OBJECT as JSON response.
		require
			object_attached: a_object /= Void
		do
			send_json (a_object.representation.to_string_8)
		end

	send_json_array (a_array: SIMPLE_JSON_ARRAY)
			-- Send SIMPLE_JSON_ARRAY as JSON response.
		require
			array_attached: a_array /= Void
		do
			send_json (a_array.representation.to_string_8)
		end

	send_empty
			-- Send empty response (typically with 204 No Content).
		do
			if is_mock then
				mock_headers.force ("0", "Content-Length")
				mock_body.wipe_out
			elseif attached wsf_response as l_response then
				l_response.set_status_code (status_code)
				l_response.put_header_text ("Content-Length: 0%R%N%R%N")
			end
		end

	send_redirect (a_url: READABLE_STRING_8)
			-- Send redirect response to `a_url'.
		require
			url_attached: a_url /= Void
		do
			if status_code = 200 then
				status_code := 302
			end
			if is_mock then
				mock_headers.force (a_url.to_string_8, "Location")
			elseif attached wsf_response as l_response then
				l_response.set_status_code (status_code)
				l_response.put_header_text ("Location: " + a_url + "%R%N%R%N")
			end
		end

	send_error (a_status: INTEGER; a_message: READABLE_STRING_8)
			-- Send error response with `a_status' code and JSON error `a_message'.
			-- Convenience method combining set_status + send_json for error responses.
		require
			valid_status: a_status >= 400 and a_status < 600
			message_attached: a_message /= Void
		do
			set_status (a_status)
			send_json ("{%"error%":%"" + a_message + "%"}")
		ensure
			status_set: status_code = a_status
		end

	send_bad_request (a_message: READABLE_STRING_8)
			-- Send 400 Bad Request with error message.
		require
			message_attached: a_message /= Void
		do
			send_error (400, a_message)
		ensure
			status_set: status_code = 400
		end

	send_not_found (a_message: READABLE_STRING_8)
			-- Send 404 Not Found with error message.
		require
			message_attached: a_message /= Void
		do
			send_error (404, a_message)
		ensure
			status_set: status_code = 404
		end

	send_server_error (a_message: READABLE_STRING_8)
			-- Send 500 Internal Server Error with error message.
		require
			message_attached: a_message /= Void
		do
			send_error (500, a_message)
		ensure
			status_set: status_code = 500
		end

feature -- Header Setting

	set_header (a_name: STRING_8; a_value: STRING_8)
			-- Set HTTP header.
		require
			name_attached: a_name /= Void
			value_attached: a_value /= Void
		do
			if is_mock then
				mock_headers.force (a_value, a_name)
			elseif attached wsf_response as l_response then
				l_response.put_header_text (a_name + ": " + a_value + "%R%N")
			end
		end

feature {NONE} -- Implementation

	send_with_content_type (a_content: READABLE_STRING_8; a_content_type: STRING)
			-- Send `a_content' with specified content type.
		require
			content_attached: a_content /= Void
			content_type_attached: a_content_type /= Void
		local
			l_header: STRING
		do
			if is_mock then
				mock_headers.force (a_content_type, "Content-Type")
				mock_headers.force (a_content.count.out, "Content-Length")
				mock_body.wipe_out
				mock_body.append (a_content.to_string_8)
			elseif attached wsf_response as l_response then
				l_response.set_status_code (status_code)
				create l_header.make (100)
				l_header.append ("Content-Type: ")
				l_header.append (a_content_type)
				l_header.append ("%R%NContent-Length: ")
				l_header.append_integer (a_content.count)
				l_header.append ("%R%N%R%N")
				l_response.put_header_text (l_header)
				l_response.put_string (a_content)
			end
		end

invariant
	wsf_response_attached_or_mock: is_mock or wsf_response /= Void
	valid_status_code: status_code >= 100 and status_code < 600
	mock_headers_attached: mock_headers /= Void
	mock_body_attached: mock_body /= Void

note
	copyright: "Copyright (c) 2024-2025, Larry Rix"
	license: "MIT License"

end
