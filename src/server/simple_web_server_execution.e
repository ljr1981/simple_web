note
	description: "[
		WSF execution handler for SIMPLE_WEB_SERVER.
		Dispatches incoming requests to registered route handlers.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_WEB_SERVER_EXECUTION

inherit
	WSF_EXECUTION

create
	make

feature -- Execution

	execute
			-- Execute the request through middleware pipeline, then route handler.
		local
			l_request: SIMPLE_WEB_SERVER_REQUEST
			l_response: SIMPLE_WEB_SERVER_RESPONSE
		do
			create l_request.make (request)
			create l_response.make (response)

			-- Execute through middleware pipeline, ending with route dispatch
			router.middleware_pipeline.execute (
				l_request,
				l_response,
				agent dispatch_to_route (l_request, l_response)
			)
		end

feature {NONE} -- Route Dispatch

	dispatch_to_route (a_request: SIMPLE_WEB_SERVER_REQUEST; a_response: SIMPLE_WEB_SERVER_RESPONSE)
			-- Find and execute matching route handler.
		local
			l_route: detachable SIMPLE_WEB_SERVER_ROUTE
			l_path: STRING_32
			l_params: HASH_TABLE [STRING_32, STRING_32]
			l_keys: ARRAY [STRING_32]
			i: INTEGER
		do
			l_path := a_request.path

			-- Find matching route using shared router
			l_route := router.find_route (a_request.method, l_path)

			if l_route /= Void then
				-- Extract and set path parameters
				l_params := l_route.extract_path_parameters (l_path)
				l_keys := l_params.current_keys
				from
					i := l_keys.lower
				until
					i > l_keys.upper
				loop
					if attached l_params.item (l_keys [i]) as l_value then
						a_request.set_path_parameter (l_keys [i], l_value)
					end
					i := i + 1
				end
				-- Call handler
				l_route.handler.call ([a_request, a_response])
			else
				-- No route found - send 404
				a_response.set_not_found
				a_response.send_json ("{%"error%":%"Not Found%",%"path%":%"" + l_path.to_string_8 + "%"}")
			end
		end

feature {NONE} -- Implementation

	router: SIMPLE_WEB_SERVER_ROUTER
			-- Shared router singleton.
		once
			create Result
		ensure
			result_attached: Result /= Void
		end

note
	copyright: "Copyright (c) 2024-2025, Larry Rix"
	license: "MIT License"

end
