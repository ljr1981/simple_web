note
	description: "[
		Shared router singleton for SIMPLE_WEB_SERVER.
		Holds routes that are accessed by execution instances.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_WEB_SERVER_ROUTER

feature -- Access

	routes: ARRAYED_LIST [SIMPLE_WEB_SERVER_ROUTE]
			-- Registered routes.
		once
			create Result.make (20)
		ensure
			result_attached: Result /= Void
		end

feature -- Route Registration

	add_route (a_route: SIMPLE_WEB_SERVER_ROUTE)
			-- Add a route.
		require
			route_attached: a_route /= Void
		do
			routes.extend (a_route)
		ensure
			route_added: routes.has (a_route)
		end

	clear_routes
			-- Remove all routes.
		do
			routes.wipe_out
		ensure
			routes_empty: routes.is_empty
		end

feature -- Matching

	find_route (a_method: STRING; a_path: STRING_32): detachable SIMPLE_WEB_SERVER_ROUTE
			-- Find route matching `a_method' and `a_path'.
		require
			method_attached: a_method /= Void
			path_attached: a_path /= Void
		local
			i: INTEGER
			l_route: SIMPLE_WEB_SERVER_ROUTE
		do
			from
				i := 1
			until
				i > routes.count or Result /= Void
			loop
				l_route := routes.i_th (i)
				if l_route.matches (a_method, a_path) then
					Result := l_route
				end
				i := i + 1
			end
		end

note
	copyright: "Copyright (c) 2024-2025, Larry Rix"
	license: "MIT License"

end
