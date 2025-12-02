note
	description: "[
		Middleware pipeline that chains middleware execution.

		Middleware runs in registration order for pre-processing,
		and reverse order for post-processing (like a stack).

		Usage:
			pipeline.use (create {LOGGING_MIDDLEWARE})
			pipeline.use (create {CORS_MIDDLEWARE})
			pipeline.use (create {AUTH_MIDDLEWARE})
			pipeline.execute (request, response, final_handler)

		Execution order:
			1. LOGGING pre-process
			2. CORS pre-process
			3. AUTH pre-process
			4. Route handler
			5. AUTH post-process
			6. CORS post-process
			7. LOGGING post-process
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_WEB_MIDDLEWARE_PIPELINE

create
	make

feature {NONE} -- Initialization

	make
			-- Create empty pipeline.
		do
			create middleware_list.make (5)
		ensure
			empty: middleware_list.is_empty
		end

feature -- Access

	middleware_list: ARRAYED_LIST [SIMPLE_WEB_MIDDLEWARE]
			-- Registered middleware in execution order.

	count: INTEGER
			-- Number of middleware in pipeline.
		do
			Result := middleware_list.count
		end

	is_empty: BOOLEAN
			-- Is pipeline empty?
		do
			Result := middleware_list.is_empty
		end

feature -- Element change

	use (a_middleware: SIMPLE_WEB_MIDDLEWARE)
			-- Add `a_middleware' to the pipeline.
		require
			middleware_attached: a_middleware /= Void
		do
			middleware_list.extend (a_middleware)
		ensure
			added: middleware_list.has (a_middleware)
			count_increased: count = old count + 1
		end

	clear
			-- Remove all middleware.
		do
			middleware_list.wipe_out
		ensure
			empty: is_empty
		end

feature -- Execution

	execute (a_request: SIMPLE_WEB_SERVER_REQUEST; a_response: SIMPLE_WEB_SERVER_RESPONSE; a_final_handler: PROCEDURE)
			-- Execute pipeline, ending with `a_final_handler'.
		require
			request_attached: a_request /= Void
			response_attached: a_response /= Void
			handler_attached: a_final_handler /= Void
		do
			if middleware_list.is_empty then
				-- No middleware, just run handler
				a_final_handler.call (Void)
			else
				-- Start chain with first middleware
				execute_at_index (1, a_request, a_response, a_final_handler)
			end
		end

feature {NONE} -- Implementation

	execute_at_index (a_index: INTEGER; a_request: SIMPLE_WEB_SERVER_REQUEST; a_response: SIMPLE_WEB_SERVER_RESPONSE; a_final_handler: PROCEDURE)
			-- Execute middleware at `a_index', chaining to next.
		require
			valid_index: a_index >= 1 and a_index <= middleware_list.count
		local
			l_middleware: SIMPLE_WEB_MIDDLEWARE
			l_next: PROCEDURE
		do
			l_middleware := middleware_list [a_index]

			if a_index < middleware_list.count then
				-- More middleware in chain
				l_next := agent execute_at_index (a_index + 1, a_request, a_response, a_final_handler)
			else
				-- Last middleware, next is the final handler
				l_next := a_final_handler
			end

			l_middleware.process (a_request, a_response, l_next)
		end

invariant
	middleware_list_attached: middleware_list /= Void

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
