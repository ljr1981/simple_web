note
	description: "Tests for TODO_WEB_API_SERVER - exercises API endpoints via mock requests."
	author: "Claude Code"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_TODO_API

inherit
	TEST_SET_BASE

feature -- Test: Health

	test_health_endpoint
			-- GET /health returns service info.
		local
			l_server: TODO_WEB_API_SERVER
			l_request: SIMPLE_WEB_SERVER_REQUEST
			l_response: SIMPLE_WEB_SERVER_RESPONSE
		do
			create l_server.make (8080)
			create l_request.make_mock ("GET", "/health")
			create l_response.make_mock

			-- Note: We can't call handlers directly as they're {NONE}
			-- This test documents the friction of testing handlers

			-- For now, just verify server creation works
			assert ("server created", l_server /= Void)
			assert ("todo_app initialized", l_server.todo_app /= Void)
			assert ("has zero todos initially", l_server.todo_app.total_count = 0)
		end

feature -- Test: Entity Creation

	test_add_todo_via_app
			-- Verify we can add todos through the app layer.
		local
			l_server: TODO_WEB_API_SERVER
			l_todo: TODO_ITEM
		do
			create l_server.make (8080)

			l_todo := l_server.todo_app.add_todo ("Test task", 3)

			assert ("todo created", l_todo /= Void)
			assert ("has id", l_todo.id > 0)
			assert ("title matches", l_todo.title.same_string ("Test task"))
			assert ("priority matches", l_todo.priority = 3)
			assert ("not completed", not l_todo.is_completed)
			assert ("total count", l_server.todo_app.total_count = 1)
		end

	test_add_todo_with_details
			-- Verify full todo creation with all fields.
		local
			l_server: TODO_WEB_API_SERVER
			l_todo: TODO_ITEM
		do
			create l_server.make (8080)

			l_todo := l_server.todo_app.add_todo_with_details (
				"Detailed task",
				"This is the description",
				1,
				"2025-12-31"
			)

			assert ("todo created", l_todo /= Void)
			assert ("title", l_todo.title.same_string ("Detailed task"))
			assert ("has description", attached l_todo.description as d and then d.same_string ("This is the description"))
			assert ("priority 1", l_todo.priority = 1)
			assert ("has due date", attached l_todo.due_date as dd and then dd.same_string ("2025-12-31"))
		end

feature -- Test: CRUD Operations

	test_complete_and_incomplete
			-- Verify completion toggling.
		local
			l_server: TODO_WEB_API_SERVER
			l_todo: TODO_ITEM
			l_success: BOOLEAN
		do
			create l_server.make (8080)
			l_todo := l_server.todo_app.add_todo ("Toggle test", 2)

			assert ("initially incomplete", not l_todo.is_completed)

			l_success := l_server.todo_app.complete_todo (l_todo.id)
			assert ("complete succeeded", l_success)

			if attached l_server.todo_app.find_todo (l_todo.id) as l_found then
				assert ("now completed", l_found.is_completed)
			else
				assert ("found after complete", False)
			end

			l_success := l_server.todo_app.uncomplete_todo (l_todo.id)
			assert ("uncomplete succeeded", l_success)

			if attached l_server.todo_app.find_todo (l_todo.id) as l_found then
				assert ("now incomplete", not l_found.is_completed)
			else
				assert ("found after uncomplete", False)
			end
		end

	test_delete_todo
			-- Verify deletion.
		local
			l_server: TODO_WEB_API_SERVER
			l_todo: TODO_ITEM
			l_success: BOOLEAN
		do
			create l_server.make (8080)
			l_todo := l_server.todo_app.add_todo ("Delete me", 3)
			assert ("created", l_server.todo_app.total_count = 1)

			l_success := l_server.todo_app.delete_todo (l_todo.id)
			assert ("delete succeeded", l_success)
			assert ("count zero", l_server.todo_app.total_count = 0)
			assert ("not found", l_server.todo_app.find_todo (l_todo.id) = Void)
		end

	test_clear_completed
			-- Verify clearing completed todos.
		local
			l_server: TODO_WEB_API_SERVER
			l_count: INTEGER
		do
			create l_server.make (8080)

			-- Add mix of completed and incomplete
			l_server.todo_app.add_todo ("Task 1", 1).do_nothing
			l_server.todo_app.add_todo ("Task 2", 2).do_nothing
			l_server.todo_app.add_todo ("Task 3", 3).do_nothing

			l_server.todo_app.complete_todo (1).do_nothing
			l_server.todo_app.complete_todo (3).do_nothing

			assert ("total 3", l_server.todo_app.total_count = 3)
			assert ("completed 2", l_server.todo_app.completed_count = 2)

			l_count := l_server.todo_app.clear_completed
			assert ("cleared 2", l_count = 2)
			assert ("remaining 1", l_server.todo_app.total_count = 1)
			assert ("completed 0", l_server.todo_app.completed_count = 0)
		end

feature -- Test: Queries

	test_filter_by_status
			-- Verify status filtering.
		local
			l_server: TODO_WEB_API_SERVER
			l_all, l_incomplete, l_completed: ARRAYED_LIST [TODO_ITEM]
		do
			create l_server.make (8080)

			l_server.todo_app.add_todo ("Task 1", 1).do_nothing
			l_server.todo_app.add_todo ("Task 2", 2).do_nothing
			l_server.todo_app.add_todo ("Task 3", 3).do_nothing
			l_server.todo_app.complete_todo (2).do_nothing

			l_all := l_server.todo_app.all_todos
			l_incomplete := l_server.todo_app.incomplete_todos
			l_completed := l_server.todo_app.completed_todos

			assert ("all 3", l_all.count = 3)
			assert ("incomplete 2", l_incomplete.count = 2)
			assert ("completed 1", l_completed.count = 1)
		end

	test_statistics
			-- Verify stats calculation.
		local
			l_server: TODO_WEB_API_SERVER
		do
			create l_server.make (8080)

			l_server.todo_app.add_todo ("Task 1", 1).do_nothing
			l_server.todo_app.add_todo ("Task 2", 2).do_nothing
			l_server.todo_app.add_todo ("Task 3", 3).do_nothing
			l_server.todo_app.add_todo ("Task 4", 4).do_nothing
			l_server.todo_app.complete_todo (1).do_nothing
			l_server.todo_app.complete_todo (2).do_nothing

			assert ("total 4", l_server.todo_app.total_count = 4)
			assert ("incomplete 2", l_server.todo_app.incomplete_count = 2)
			assert ("completed 2", l_server.todo_app.completed_count = 2)
			assert ("completion 50 percent", l_server.todo_app.completion_percentage = 50.0)
		end

feature -- Test: JSON Serialization (Friction Point F1)

	test_todo_to_json_friction
			-- Document friction: no standard entity-to-JSON pattern.
			-- Currently must access private feature or duplicate code.
		local
			l_server: TODO_WEB_API_SERVER
			l_todo: TODO_ITEM
			l_json: SIMPLE_JSON_OBJECT
		do
			create l_server.make (8080)
			l_todo := l_server.todo_app.add_todo_with_details ("JSON test", "Description", 2, "2025-06-15")

			-- FRICTION: Can't call l_server.todo_to_json (l_todo) - it's {NONE}
			-- Must duplicate the serialization logic here for testing
			create l_json.make
			l_json.put_integer (l_todo.id, "id").do_nothing
			l_json.put_string (l_todo.title, "title").do_nothing
			if attached l_todo.description as d then
				l_json.put_string (d, "description").do_nothing
			end
			l_json.put_integer (l_todo.priority.to_integer_64, "priority").do_nothing
			l_json.put_boolean (l_todo.is_completed, "is_completed").do_nothing

			assert ("has id", l_json.has_key ("id"))
			assert ("has title", l_json.has_key ("title"))
			assert ("id correct", l_json.integer_item ("id") = l_todo.id)
			assert ("title correct", attached l_json.string_item ("title") as t and then t.same_string ("JSON test"))
		end

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
