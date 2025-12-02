note
	description: "Middleware that blocks the chain (for testing short-circuit)."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_BLOCKING_MIDDLEWARE

inherit
	SIMPLE_WEB_MIDDLEWARE

create
	make

feature {NONE} -- Initialization

	make
		do
			did_block := False
		end

feature -- Access

	name: STRING = "test_blocker"

	did_block: BOOLEAN

feature -- Processing

	process (a_request: SIMPLE_WEB_SERVER_REQUEST; a_response: SIMPLE_WEB_SERVER_RESPONSE; a_next: PROCEDURE)
		do
			did_block := True
			-- Intentionally NOT calling a_next - short-circuits the chain
			a_response.set_status (403)
		end

end
