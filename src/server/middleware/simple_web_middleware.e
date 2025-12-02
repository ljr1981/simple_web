note
	description: "[
		Abstract base class for HTTP middleware.

		Middleware can:
		- Modify requests before handlers run (pre-processing)
		- Short-circuit requests (e.g., return 401 for auth failure)
		- Modify responses after handlers run (post-processing)

		Implement `process` to define middleware behavior. Call `next.call`
		to continue the chain, or set response directly to short-circuit.

		Example:
			class LOGGING_MIDDLEWARE inherit SIMPLE_WEB_MIDDLEWARE
			feature
				process (req: SIMPLE_WEB_SERVER_REQUEST; res: SIMPLE_WEB_SERVER_RESPONSE; next: PROCEDURE)
					do
						print ("Request: " + req.method + " " + req.path + "%N")
						next.call  -- Continue to next middleware/handler
						print ("Response: " + res.status_code.out + "%N")
					end
			end
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	SIMPLE_WEB_MIDDLEWARE

feature -- Processing

	process (a_request: SIMPLE_WEB_SERVER_REQUEST; a_response: SIMPLE_WEB_SERVER_RESPONSE; a_next: PROCEDURE)
			-- Process the request/response.
			-- Call `a_next.call` to continue chain, or set response to short-circuit.
		require
			request_attached: a_request /= Void
			response_attached: a_response /= Void
			next_attached: a_next /= Void
		deferred
		end

feature -- Access

	name: STRING
			-- Middleware name for logging/debugging.
		deferred
		ensure
			result_not_empty: Result /= Void and then not Result.is_empty
		end

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
