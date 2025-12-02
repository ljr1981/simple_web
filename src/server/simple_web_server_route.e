note
	description: "[
		Route definition for HTTP server.
		Matches HTTP method and URL pattern to handler agent.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_WEB_SERVER_ROUTE

create
	make

feature {NONE} -- Initialization

	make (a_method, a_pattern: STRING; a_handler: PROCEDURE [SIMPLE_WEB_SERVER_REQUEST, SIMPLE_WEB_SERVER_RESPONSE])
			-- Create route for `a_method' requests to `a_pattern' handled by `a_handler'.
		require
			method_attached: a_method /= Void
			pattern_attached: a_pattern /= Void
			handler_attached: a_handler /= Void
		do
			method := a_method.as_upper
			pattern := a_pattern
			handler := a_handler
			parse_pattern
		ensure
			method_set: method.is_case_insensitive_equal (a_method)
			pattern_set: pattern = a_pattern
			handler_set: handler = a_handler
		end

feature -- Access

	method: STRING
			-- HTTP method (GET, POST, PUT, DELETE, etc.).

	pattern: STRING
			-- URL pattern (e.g., "/api/users/{id}").

	handler: PROCEDURE [SIMPLE_WEB_SERVER_REQUEST, SIMPLE_WEB_SERVER_RESPONSE]
			-- Handler procedure for this route.

feature -- Matching

	matches (a_method: STRING; a_path: STRING_32): BOOLEAN
			-- Does this route match the given method and path?
		require
			method_attached: a_method /= Void
			path_attached: a_path /= Void
		do
			if method.is_case_insensitive_equal (a_method) then
				Result := path_matches (a_path)
			end
		end

	path_matches (a_path: STRING_32): BOOLEAN
			-- Does `a_path' match this route's pattern?
		local
			l_path_segments, l_pattern_segments: LIST [STRING_32]
			i: INTEGER
			l_seg, l_pat_seg: STRING_32
		do
			l_path_segments := a_path.split ('/')
			l_pattern_segments := pattern.as_string_32.split ('/')

			-- Remove empty segments from leading/trailing slashes
			from until l_path_segments.is_empty or else not l_path_segments.first.is_empty loop
				l_path_segments.start
				l_path_segments.remove
			end
			from until l_path_segments.is_empty or else not l_path_segments.last.is_empty loop
				l_path_segments.finish
				l_path_segments.remove
			end
			from until l_pattern_segments.is_empty or else not l_pattern_segments.first.is_empty loop
				l_pattern_segments.start
				l_pattern_segments.remove
			end
			from until l_pattern_segments.is_empty or else not l_pattern_segments.last.is_empty loop
				l_pattern_segments.finish
				l_pattern_segments.remove
			end

			if l_path_segments.count = l_pattern_segments.count then
				Result := True
				from
					i := 1
				until
					i > l_pattern_segments.count or not Result
				loop
					l_pat_seg := l_pattern_segments.i_th (i)
					l_seg := l_path_segments.i_th (i)
					if l_pat_seg.count >= 2 and then l_pat_seg.item (1) = '{' and then l_pat_seg.item (l_pat_seg.count) = '}' then
						-- Parameter placeholder matches any non-empty segment
						Result := not l_seg.is_empty
					else
						-- Literal segment must match exactly
						Result := l_seg.same_string (l_pat_seg)
					end
					i := i + 1
				end
			end
		end

	extract_path_parameters (a_path: STRING_32): HASH_TABLE [STRING_32, STRING_32]
			-- Extract path parameters from `a_path'.
			-- For pattern "/users/{id}" and path "/users/123", returns ["id" -> "123"].
		require
			path_attached: a_path /= Void
			path_matches: path_matches (a_path)
		local
			l_path_segments, l_pattern_segments: LIST [STRING_32]
			l_param_name: STRING_32
			i: INTEGER
		do
			create Result.make (parameter_names.count)
			l_path_segments := a_path.split ('/')
			l_pattern_segments := pattern.as_string_32.split ('/')

			from
				i := 1
			until
				i > l_pattern_segments.count or i > l_path_segments.count
			loop
				if attached l_pattern_segments.i_th (i) as l_seg then
					if l_seg.count >= 2 and then l_seg.item (1) = '{' and then l_seg.item (l_seg.count) = '}' then
						l_param_name := l_seg.substring (2, l_seg.count - 1)
						Result.force (l_path_segments.i_th (i), l_param_name)
					end
				end
				i := i + 1
			end
		ensure
			result_attached: Result /= Void
		end

feature {NONE} -- Implementation

	parameter_names: ARRAYED_LIST [STRING]
			-- Names of path parameters in order.

	regex_pattern: detachable STRING
			-- Compiled regex pattern for matching.

	parse_pattern
			-- Parse pattern to extract parameter names and build regex.
		local
			l_segments: LIST [STRING_32]
			l_regex: STRING
			l_seg: STRING_32
			l_param: STRING
			i: INTEGER
		do
			create parameter_names.make (3)
			create l_regex.make (pattern.count + 20)
			l_regex.append_character ('^')

			l_segments := pattern.as_string_32.split ('/')
			from
				i := 1
			until
				i > l_segments.count
			loop
				l_seg := l_segments.i_th (i)
				if not l_seg.is_empty then
					l_regex.append_character ('/')
					if l_seg.count >= 2 and then l_seg.item (1) = '{' and then l_seg.item (l_seg.count) = '}' then
						-- This is a parameter placeholder
						l_param := l_seg.substring (2, l_seg.count - 1).to_string_8
						parameter_names.extend (l_param)
						l_regex.append ("([^/]+)")
					else
						-- Literal segment - escape regex special chars
						l_regex.append (escape_regex (l_seg.to_string_8))
					end
				end
				i := i + 1
			end

			if pattern.is_empty or else pattern.same_string ("/") then
				l_regex.wipe_out
				l_regex.append ("^/$")
			else
				l_regex.append_character ('$')
			end

			regex_pattern := l_regex
		end

	escape_regex (s: STRING): STRING
			-- Escape special regex characters in `s'.
		local
			i: INTEGER
			c: CHARACTER
		do
			create Result.make (s.count)
			from i := 1 until i > s.count loop
				c := s.item (i)
				inspect c
				when '.', '*', '+', '?', '^', '$', '[', ']', '(', ')', '{', '}', '|', '\' then
					Result.append_character ('\')
					Result.append_character (c)
				else
					Result.append_character (c)
				end
				i := i + 1
			end
		end

invariant
	method_attached: method /= Void
	pattern_attached: pattern /= Void
	handler_attached: handler /= Void
	parameter_names_attached: parameter_names /= Void

note
	copyright: "Copyright (c) 2024-2025, Larry Rix"
	license: "MIT License"

end
