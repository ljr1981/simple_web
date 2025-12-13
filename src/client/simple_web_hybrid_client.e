note
	description: "[
		Hybrid HTTP client that works around curl_http_client library issues.
		Uses curl.exe process for POST/PUT (broken in libcurl for localhost).
		Uses libcurl for GET/DELETE (works fine).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_WEB_HYBRID_CLIENT

inherit
	SIMPLE_WEB_CONSTANTS

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize hybrid client
		do
			create process_helper
			create libcurl_client.make
		end

feature -- Basic Operations

	get (a_url: STRING): SIMPLE_WEB_RESPONSE
			-- Execute GET request (uses libcurl - works fine)
		require
			url_not_empty: not a_url.is_empty
		do
			Result := libcurl_client.get (a_url)
		ensure
			result_attached: Result /= Void
		end

	post_json (a_url, a_json_body: STRING): SIMPLE_WEB_RESPONSE
			-- Execute POST with JSON body (uses curl.exe process)
		require
			url_not_empty: not a_url.is_empty
			body_attached: a_json_body /= Void
		do
			Result := execute_curl_process ("POST", a_url, a_json_body)
		ensure
			result_attached: Result /= Void
		end

	put_json (a_url, a_json_body: STRING): SIMPLE_WEB_RESPONSE
			-- Execute PUT with JSON body (uses curl.exe process)
		require
			url_not_empty: not a_url.is_empty
			body_attached: a_json_body /= Void
		do
			Result := execute_curl_process ("PUT", a_url, a_json_body)
		ensure
			result_attached: Result /= Void
		end

	delete (a_url: STRING): SIMPLE_WEB_RESPONSE
			-- Execute DELETE request (uses libcurl)
		require
			url_not_empty: not a_url.is_empty
		do
			Result := libcurl_client.delete (a_url)
		ensure
			result_attached: Result /= Void
		end

feature -- Advanced Operations

	post_json_with_headers (a_url, a_json_body: STRING; a_headers: STRING_TABLE [STRING]): SIMPLE_WEB_RESPONSE
			-- Execute POST with JSON body and custom headers
		require
			url_not_empty: not a_url.is_empty
			body_attached: a_json_body /= Void
		do
			Result := execute_curl_process_with_headers ("POST", a_url, a_json_body, a_headers)
		ensure
			result_attached: Result /= Void
		end

feature {NONE} -- Implementation

	execute_curl_process (a_method, a_url, a_body: STRING): SIMPLE_WEB_RESPONSE
			-- Execute HTTP request via curl.exe process
		local
			l_cmd: STRING
			l_output: STRING
			l_escaped_body: STRING
		do
			l_escaped_body := escape_json_for_cmd (a_body)

			create l_cmd.make (256)
			l_cmd.append ("curl.exe -s -X ")
			l_cmd.append (a_method)
			l_cmd.append (" ")
			l_cmd.append (a_url)
			l_cmd.append (" -H %"Content-Type: application/json%"")
			l_cmd.append (" -w %"")
			l_cmd.append (Status_delimiter)
			l_cmd.append ("%%{http_code}%"")
			l_cmd.append (" -d %"")
			l_cmd.append (l_escaped_body)
			l_cmd.append ("%"")

			l_output := process_helper.shell_output (l_cmd, Void)
			Result := parse_curl_output (l_output)
		end

	execute_curl_process_with_headers (a_method, a_url, a_body: STRING; a_headers: detachable STRING_TABLE [STRING]): SIMPLE_WEB_RESPONSE
			-- Execute HTTP request via curl.exe with custom headers
		local
			l_cmd: STRING
			l_output: STRING
			l_escaped_body: STRING
		do
			l_escaped_body := escape_json_for_cmd (a_body)

			create l_cmd.make (512)
			l_cmd.append ("curl.exe -s -X ")
			l_cmd.append (a_method)
			l_cmd.append (" ")
			l_cmd.append (a_url)
			l_cmd.append (" -H %"Content-Type: application/json%"")

			-- Add custom headers
			if attached a_headers as al_headers then
				across al_headers as ic loop
					l_cmd.append (" -H %"")
					l_cmd.append (ic)
					l_cmd.append (": ")
					l_cmd.append (ic)
					l_cmd.append ("%"")
				end
			end

			l_cmd.append (" -w %"")
			l_cmd.append (Status_delimiter)
			l_cmd.append ("%%{http_code}%"")
			l_cmd.append (" -d %"")
			l_cmd.append (l_escaped_body)
			l_cmd.append ("%"")

			l_output := process_helper.shell_output (l_cmd, Void)
			Result := parse_curl_output (l_output)
		end

	parse_curl_output (a_output: STRING): SIMPLE_WEB_RESPONSE
			-- Parse curl output into response object
		local
			l_delimiter_pos: INTEGER
			l_body: STRING
			l_status_str: STRING
			l_status: INTEGER
		do
			l_delimiter_pos := a_output.substring_index (Status_delimiter, 1)

			if l_delimiter_pos > 0 then
				l_body := a_output.substring (1, l_delimiter_pos - 1)
				l_status_str := a_output.substring (l_delimiter_pos + Status_delimiter.count, a_output.count)
				l_status_str.right_adjust
				l_status_str.left_adjust
				if l_status_str.is_integer then
					l_status := l_status_str.to_integer
				else
					l_status := Status_service_unavailable
				end
			else
				-- No delimiter found - assume failure
				l_body := a_output
				l_status := Status_service_unavailable
			end

			create Result.make_with_body (l_status, l_body)
		end

	escape_json_for_cmd (a_json: STRING): STRING
			-- Escape JSON for Windows command line
		local
			i: INTEGER
			c: CHARACTER
		do
			create Result.make (a_json.count + 20)
			from
				i := 1
			until
				i > a_json.count
			loop
				c := a_json.item (i)
				inspect c
				when '"' then
					Result.append ("\%"")
				when '\' then
					Result.append ("\\")
				else
					Result.append_character (c)
				end
				i := i + 1
			end
		end

feature {NONE} -- Implementation Attributes

	process_helper: SIMPLE_PROCESS_HELPER
			-- Process execution helper

	libcurl_client: SIMPLE_WEB_CLIENT
			-- Libcurl-based client for GET/DELETE

feature {NONE} -- Constants

	Status_delimiter: STRING = "|||HTTP_STATUS|||"
			-- Delimiter between body and status code in curl output

note
	copyright: "Copyright (c) 2024-2025, Larry Rix"
	license: "MIT License"
	source: "[
		SIMPLE_WEB - High-level Web API Library
		Hybrid client working around curl_http_client POST issues
	]"

end
