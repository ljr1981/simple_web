note
	description: "Middleware that records execution order for testing."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_ORDER_MIDDLEWARE

inherit
	SIMPLE_WEB_MIDDLEWARE

create
	make

feature {NONE} -- Initialization

	make (a_name: STRING; a_list: ARRAYED_LIST [STRING])
		do
			name := a_name
			order_list := a_list
		end

feature -- Access

	name: STRING

	order_list: ARRAYED_LIST [STRING]

feature -- Processing

	process (a_request: SIMPLE_WEB_SERVER_REQUEST; a_response: SIMPLE_WEB_SERVER_RESPONSE; a_next: PROCEDURE)
		do
			order_list.extend (name)
			a_next.call (Void)
		end

end
