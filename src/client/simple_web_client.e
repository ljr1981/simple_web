note
	description: "[
		High-level HTTP client for making web requests.
		Wraps EiffelStudio's http_client library with clean, simple API.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_WEB_CLIENT

inherit
	SIMPLE_WEB_CONSTANTS

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize HTTP client
		do
			-- Client will be created fresh for each request
		end

feature -- Basic Operations

	get (a_url: STRING): SIMPLE_WEB_RESPONSE
			-- Execute GET request
		require
			url_attached: a_url /= Void
			url_not_empty: not a_url.is_empty
		local
			l_request: SIMPLE_WEB_REQUEST
		do
			create l_request.make_get (a_url)
			Result := execute (l_request)
		ensure
			result_attached: Result /= Void
		end

	post (a_url, a_body: STRING): SIMPLE_WEB_RESPONSE
			-- Execute POST request with body
		require
			url_attached: a_url /= Void
			url_not_empty: not a_url.is_empty
			body_attached: a_body /= Void
		local
			l_request: SIMPLE_WEB_REQUEST
		do
			create l_request.make_post (a_url)
			l_request.with_body (a_body).do_nothing
			Result := execute (l_request)
		ensure
			result_attached: Result /= Void
		end

	post_json (a_url, a_json: STRING): SIMPLE_WEB_RESPONSE
			-- Execute POST request with JSON body
		require
			url_attached: a_url /= Void
			url_not_empty: not a_url.is_empty
			json_attached: a_json /= Void
		local
			l_request: SIMPLE_WEB_REQUEST
		do
			create l_request.make_post (a_url)
			l_request.with_json_body (a_json).do_nothing
			Result := execute (l_request)
		ensure
			result_attached: Result /= Void
		end

	put (a_url, a_body: STRING): SIMPLE_WEB_RESPONSE
			-- Execute PUT request with body
		require
			url_attached: a_url /= Void
			url_not_empty: not a_url.is_empty
			body_attached: a_body /= Void
		local
			l_request: SIMPLE_WEB_REQUEST
		do
			create l_request.make_put (a_url)
			l_request.with_body (a_body).do_nothing
			Result := execute (l_request)
		ensure
			result_attached: Result /= Void
		end

	delete (a_url: STRING): SIMPLE_WEB_RESPONSE
			-- Execute DELETE request
		require
			url_attached: a_url /= Void
			url_not_empty: not a_url.is_empty
		local
			l_request: SIMPLE_WEB_REQUEST
		do
			create l_request.make_delete (a_url)
			Result := execute (l_request)
		ensure
			result_attached: Result /= Void
		end

feature -- Advanced Operations

	execute (a_request: SIMPLE_WEB_REQUEST): SIMPLE_WEB_RESPONSE
			-- Execute HTTP request using configured client
		require
			request_attached: a_request /= Void
		local
			l_session: CURL_HTTP_CLIENT_SESSION
			l_ctx: HTTP_CLIENT_REQUEST_CONTEXT
			l_response: detachable HTTP_CLIENT_RESPONSE
			l_hdr_name: STRING
			l_hdr_value: READABLE_STRING
		do
			-- Create session
			create l_session.make (a_request.url)
			create l_ctx.make

			-- Add headers to context
			across a_request.headers.current_keys as ic loop
				if attached a_request.headers.item (ic) as l_value then
					l_ctx.headers.force (l_value, ic.out)
				end
			end

			-- Set upload data if present
			if attached a_request.body as al_body and then not al_body.is_empty then
				l_ctx.set_upload_data (al_body)
			end

			-- Execute based on method
			if a_request.method ~ Http_method_get then
				l_response := l_session.get ("", l_ctx)
			elseif a_request.method ~ Http_method_post then
				l_response := l_session.post ("", l_ctx, Void)
			elseif a_request.method ~ Http_method_put then
				l_response := l_session.put ("", l_ctx, Void)
			elseif a_request.method ~ Http_method_delete then
				l_response := l_session.delete ("", l_ctx)
			end

			-- Build response
			if attached l_response as al_response then
				-- HTTP library returned a response object
				if attached al_response.body as al_body then
					-- Response has body content
					if al_response.status = 0 then
						-- Status 0 indicates network/request failure
						create Result.make (Status_service_unavailable)
					else
						-- Normal response with status and body
						create Result.make_with_body (al_response.status, al_body.to_string_8)
					end
				else
					-- Response has no body (e.g., 204 No Content, HEAD request)
					create Result.make (al_response.status)
				end

				-- Copy response headers
				if attached al_response.headers as al_headers then
					from
						al_headers.start
					until
						al_headers.off
					loop
						if attached {STRING} al_headers.item_for_iteration [1] as al_hdr_name and then
							attached {READABLE_STRING} al_headers.item_for_iteration [2] as al_hdr_value
						then
							Result.add_header (al_hdr_name, al_hdr_value)
						end
						al_headers.forth
					end
				end
			else
				-- HTTP library returned Void - complete failure
				create Result.make (Status_service_unavailable)
				Result.set_body ("Request failed")
			end
		ensure
			result_attached: Result /= Void
		end

feature -- Factory Methods

	new_request_get (a_url: STRING): SIMPLE_WEB_REQUEST
			-- Create new GET request builder
		require
			url_attached: a_url /= Void
			url_not_empty: not a_url.is_empty
		do
			create Result.make_get (a_url)
		ensure
			result_attached: Result /= Void
			correct_method: Result.method ~ Http_method_get
		end

	new_request_post (a_url: STRING): SIMPLE_WEB_REQUEST
			-- Create new POST request builder
		require
			url_attached: a_url /= Void
			url_not_empty: not a_url.is_empty
		do
			create Result.make_post (a_url)
		ensure
			result_attached: Result /= Void
			correct_method: Result.method ~ Http_method_post
		end

note
	copyright: "Copyright (c) 2024-2025, Larry Rix"
	license: "MIT License"
	source: "[
		SIMPLE_WEB - High-level Web API Library
		https://github.com/ljr1981/simple_web
	]"

end
