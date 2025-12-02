note
	description: "Helper middleware classes for testing."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_COUNTING_MIDDLEWARE

inherit
	SIMPLE_WEB_MIDDLEWARE

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize counter.
		do
			call_count := 0
		end

feature -- Access

	name: STRING = "test_counter"

	call_count: INTEGER

feature -- Processing

	process (a_request: SIMPLE_WEB_SERVER_REQUEST; a_response: SIMPLE_WEB_SERVER_RESPONSE; a_next: PROCEDURE)
		do
			call_count := call_count + 1
			a_next.call (Void)
		end

end
