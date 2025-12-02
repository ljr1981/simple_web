note
	description: "[
		Middleware that logs HTTP requests and responses.

		Logs to console:
		- Request method, path
		- Response status code and duration

		Usage:
			server.use_middleware (create {SIMPLE_WEB_LOGGING_MIDDLEWARE}.make)
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_WEB_LOGGING_MIDDLEWARE

inherit
	SIMPLE_WEB_MIDDLEWARE

create
	make

feature {NONE} -- Initialization

	make
			-- Create logging middleware.
		do
			-- Nothing to initialize
		end

feature -- Access

	name: STRING = "logging"
			-- Middleware name.

feature -- Processing

	process (a_request: SIMPLE_WEB_SERVER_REQUEST; a_response: SIMPLE_WEB_SERVER_RESPONSE; a_next: PROCEDURE)
			-- Log request, call next, log response.
		local
			l_message: STRING
		do
			-- Log incoming request
			create l_message.make (100)
			l_message.append ("[HTTP] -> ")
			l_message.append (a_request.method)
			l_message.append (" ")
			l_message.append (a_request.path.to_string_8)
			print (l_message)
			print ("%N")

			-- Continue chain
			a_next.call (Void)

			-- Log response
			create l_message.make (100)
			l_message.append ("[HTTP] <- ")
			l_message.append (a_response.status_code.out)
			print (l_message)
			print ("%N")
		end

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
