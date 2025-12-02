note
	description: "[
		Todo List REST API Server - Exposes TODO_APP operations via HTTP.

		This mock application exercises the SIMPLE_WEB server capabilities by
		wrapping the TODO_APP from simple_sql with a REST API.

		FRICTION LOG (document each pain point as discovered):

		[F1] ENTITY-TO-JSON SERIALIZATION - RESOLVED
		     Solution: SIMPLE_JSON_SERIALIZABLE mixin provides to_json pattern
		     Entities can inherit and implement to_json deferred feature

		[F2] JSON-TO-ENTITY DESERIALIZATION - RESOLVED
		     Solution: SIMPLE_JSON_SERIALIZABLE provides apply_json pattern
		     Entities implement apply_json (a_json) deferred feature

		[F3] FIELD VALIDATION BOILERPLATE - RESOLVED
		     Solution: json.has_all_keys (<<"title", "priority">>)
		     Also: json.has_any_key, json.missing_keys for detailed errors

		[F4] TYPE COERCION FROM JSON - RESOLVED
		     Solution: json.integer_32_item ("priority") - no more .to_integer_32
		     Also: json.natural_32_item for unsigned values

		[F5] OPTIONAL FIELD HANDLING - RESOLVED
		     Solution: json.optional_string ("description") returns detachable
		     Also: json.optional_integer, json.optional_boolean with defaults

		[F6] UPDATE PARTIAL FIELDS - Pattern documented
		     Use SIMPLE_JSON_SERIALIZABLE.apply_json for full updates
		     Partial updates still require field-by-field checking (inherent complexity)

		[F7] CROSS-LIBRARY DEPENDENCY - simple_sql's TODO_APP needed in simple_web
		     Current: Must configure ECF to include simple_sql cluster
		     Desired: Clean library boundary with just the repository
		     Impact: Configuration complexity, potential version issues

		[F8] DATABASE PATH CONFIGURATION - No standard pattern for DB path in web apps
		     Current: Hardcoded path or in-memory for testing
		     Desired: Environment variable or config file pattern
		     Impact: Different setup for dev/test/prod

		Endpoints:
			GET    /api/todos           - List all todos (with filters)
			GET    /api/todos/{id}      - Get todo by ID
			POST   /api/todos           - Create new todo
			PUT    /api/todos/{id}      - Update todo
			PATCH  /api/todos/{id}      - Partial update
			DELETE /api/todos/{id}      - Delete todo
			POST   /api/todos/{id}/complete   - Mark as completed
			POST   /api/todos/{id}/incomplete - Mark as incomplete
			DELETE /api/todos/completed       - Clear completed todos
			GET    /api/stats                 - Statistics
	]"
	author: "Claude Code"
	date: "$Date$"
	revision: "$Revision$"

class
	TODO_WEB_API_SERVER

inherit
	ANY
		redefine
			default_create
		end

create
	make,
	make_with_database,
	default_create

feature {NONE} -- Initialization

	default_create
			-- Create with default port and in-memory database.
		do
			make (8080)
		end

	make (a_port: INTEGER)
			-- Create Todo API server on `a_port' with in-memory database.
		require
			valid_port: a_port > 0 and a_port < 65536
		do
			port := a_port
			create todo_app.make
			create server.make (a_port)
			setup_middleware
			setup_routes
		ensure
			port_set: port = a_port
		end

	make_with_database (a_port: INTEGER; a_db_path: STRING)
			-- Create Todo API server with file-based database.
			-- [F8] FRICTION: No standard pattern for this - had to add custom constructor
		require
			valid_port: a_port > 0 and a_port < 65536
			path_not_empty: not a_db_path.is_empty
		local
			l_db: SIMPLE_SQL_DATABASE
		do
			port := a_port
			create l_db.make (a_db_path)
			create todo_app.make_with_database (l_db)
			create server.make (a_port)
			setup_middleware
			setup_routes
		ensure
			port_set: port = a_port
		end

feature -- Access

	port: INTEGER
			-- Server port.

	server: SIMPLE_WEB_SERVER
			-- HTTP server instance.

	todo_app: TODO_APP
			-- Todo application instance (from simple_sql).

feature -- Server Control

	start
			-- Start the server (blocking).
		do
			print ("Todo API Server starting on port " + port.out + "...%N")
			print ("Endpoints:%N")
			print ("  GET    /api/todos              - List todos%N")
			print ("  GET    /api/todos/{id}         - Get todo%N")
			print ("  POST   /api/todos              - Create todo%N")
			print ("  PUT    /api/todos/{id}         - Update todo%N")
			print ("  PATCH  /api/todos/{id}         - Partial update%N")
			print ("  DELETE /api/todos/{id}         - Delete todo%N")
			print ("  POST   /api/todos/{id}/complete   - Complete%N")
			print ("  POST   /api/todos/{id}/incomplete - Incomplete%N")
			print ("  DELETE /api/todos/completed    - Clear completed%N")
			print ("  GET    /api/stats              - Statistics%N")
			print ("%N")
			server.start
		end

feature {NONE} -- Setup

	setup_middleware
			-- Configure middleware pipeline.
		do
			server.use_logging
			server.use_cors
		end

	setup_routes
			-- Configure all API routes.
		do
			-- Health check
			server.on_get ("/health", agent handle_health)

			-- Todo CRUD
			server.on_get ("/api/todos", agent handle_list_todos)
			server.on_get ("/api/todos/{id}", agent handle_get_todo)
			server.on_post ("/api/todos", agent handle_create_todo)
			server.on_put ("/api/todos/{id}", agent handle_update_todo)
			server.on_patch ("/api/todos/{id}", agent handle_patch_todo)
			server.on_delete ("/api/todos/{id}", agent handle_delete_todo)

			-- Actions
			server.on_post ("/api/todos/{id}/complete", agent handle_complete_todo)
			server.on_post ("/api/todos/{id}/incomplete", agent handle_incomplete_todo)
			server.on_delete ("/api/todos/completed", agent handle_clear_completed)

			-- Stats
			server.on_get ("/api/stats", agent handle_stats)
		end

feature {NONE} -- Handlers: Health

	handle_health (req: SIMPLE_WEB_SERVER_REQUEST; res: SIMPLE_WEB_SERVER_RESPONSE)
			-- Health check endpoint.
		local
			l_json: SIMPLE_JSON_OBJECT
		do
			create l_json.make
			l_json.put_string ("ok", "status").do_nothing
			l_json.put_string ("todo-api", "service").do_nothing
			l_json.put_integer (port.to_integer_64, "port").do_nothing
			l_json.put_integer (todo_app.total_count.to_integer_64, "total_todos").do_nothing
			res.send_json_object (l_json)
		end

feature {NONE} -- Handlers: List

	handle_list_todos (req: SIMPLE_WEB_SERVER_REQUEST; res: SIMPLE_WEB_SERVER_RESPONSE)
			-- GET /api/todos - List todos with optional filters.
			-- Query params: ?status=completed|incomplete|all (default: all)
		local
			l_status: detachable STRING_32
			l_todos: ARRAYED_LIST [TODO_ITEM]
			l_array: SIMPLE_JSON_ARRAY
		do
			l_status := req.query_parameter ("status")

			if attached l_status as status then
				if status.same_string ("completed") then
					l_todos := todo_app.completed_todos
				elseif status.same_string ("incomplete") then
					l_todos := todo_app.incomplete_todos
				else
					l_todos := todo_app.all_todos
				end
			else
				l_todos := todo_app.all_todos
			end

			-- [F1] FRICTION: Must manually convert each entity to JSON
			create l_array.make
			across l_todos as t loop
				l_array.add_object (todo_to_json (t)).do_nothing
			end
			res.send_json_array (l_array)
		end

feature {NONE} -- Handlers: CRUD

	handle_get_todo (req: SIMPLE_WEB_SERVER_REQUEST; res: SIMPLE_WEB_SERVER_RESPONSE)
			-- GET /api/todos/{id} - Get single todo.
		local
			l_id_param: detachable STRING_32
		do
			l_id_param := req.path_parameter ("id")

			if attached l_id_param as id_str and then id_str.is_integer_64 then
				if attached todo_app.find_todo (id_str.to_integer_64) as l_todo then
					res.send_json_object (todo_to_json (l_todo))
				else
					send_error (res, 404, "Todo not found")
				end
			else
				send_error (res, 400, "Invalid todo ID")
			end
		end

	handle_create_todo (req: SIMPLE_WEB_SERVER_REQUEST; res: SIMPLE_WEB_SERVER_RESPONSE)
			-- POST /api/todos - Create new todo.
			-- Body: {"title": "...", "priority": 1-5, "description": "...", "due_date": "YYYY-MM-DD"}
		local
			l_json: detachable SIMPLE_JSON_OBJECT
			l_title: STRING_8
			l_description: detachable STRING_8
			l_priority: INTEGER
			l_due_date: detachable STRING_8
			l_todo: TODO_ITEM
		do
			l_json := req.body_as_json

			if attached l_json as json then
				-- [F3] FRICTIONLESS: Single call checks all required fields
				if json.has_all_keys (<<"title", "priority">>) then
					if attached json.string_item ("title") as t then
						l_title := t.to_string_8
					else
						l_title := ""
					end

					-- [F4] FRICTIONLESS: Direct INTEGER_32 extraction
					l_priority := json.integer_32_item ("priority")

					-- [F5] FRICTIONLESS: Optional fields with single call
					if attached json.optional_string ("description") as d then
						l_description := d.to_string_8
					end
					if attached json.optional_string ("due_date") as dd then
						l_due_date := dd.to_string_8
					end

					-- Validate
					if l_title.is_empty then
						send_error (res, 400, "Title cannot be empty")
					elseif l_priority < 1 or l_priority > 5 then
						send_error (res, 400, "Priority must be 1-5")
					else
						l_todo := todo_app.add_todo_with_details (l_title, l_description, l_priority, l_due_date)
						res.set_created
						res.send_json_object (todo_to_json (l_todo))
					end
				else
					send_error (res, 400, "Missing required fields: title, priority")
				end
			else
				send_error (res, 400, "Invalid JSON body")
			end
		end

	handle_update_todo (req: SIMPLE_WEB_SERVER_REQUEST; res: SIMPLE_WEB_SERVER_RESPONSE)
			-- PUT /api/todos/{id} - Full update of todo.
		local
			l_id_param: detachable STRING_32
			l_json: detachable SIMPLE_JSON_OBJECT
			l_todo: detachable TODO_ITEM
		do
			l_id_param := req.path_parameter ("id")
			l_json := req.body_as_json

			if not attached l_id_param as id_str or else not id_str.is_integer_64 then
				send_error (res, 400, "Invalid todo ID")
			elseif not attached l_json as json then
				send_error (res, 400, "Invalid JSON body")
			else
				l_todo := todo_app.find_todo (id_str.to_integer_64)
				if not attached l_todo then
					send_error (res, 404, "Todo not found")
				-- [F3] FRICTIONLESS: Single call checks all required fields
				elseif not json.has_all_keys (<<"title", "priority">>) then
					send_error (res, 400, "Missing required fields: title, priority")
				else
					-- Apply JSON to entity
					apply_json_to_todo (l_todo, json)

					-- Validate
					if l_todo.title.is_empty then
						send_error (res, 400, "Title cannot be empty")
					elseif l_todo.priority < 1 or l_todo.priority > 5 then
						send_error (res, 400, "Priority must be 1-5")
					else
						-- Update in database
						if todo_app.repository.update (l_todo) then
							res.send_json_object (todo_to_json (l_todo))
						else
							send_error (res, 500, "Failed to update todo")
						end
					end
				end
			end
		end

	handle_patch_todo (req: SIMPLE_WEB_SERVER_REQUEST; res: SIMPLE_WEB_SERVER_RESPONSE)
			-- PATCH /api/todos/{id} - Partial update of todo.
			-- [F6] FRICTION: Almost identical to PUT but with optional field handling
		local
			l_id_param: detachable STRING_32
			l_json: detachable SIMPLE_JSON_OBJECT
			l_todo: detachable TODO_ITEM
		do
			l_id_param := req.path_parameter ("id")
			l_json := req.body_as_json

			if not attached l_id_param as id_str or else not id_str.is_integer_64 then
				send_error (res, 400, "Invalid todo ID")
			elseif not attached l_json as json then
				send_error (res, 400, "Invalid JSON body")
			else
				l_todo := todo_app.find_todo (id_str.to_integer_64)
				if not attached l_todo then
					send_error (res, 404, "Todo not found")
				else
					-- Apply only provided fields
					apply_json_patch_to_todo (l_todo, json)

					-- Validate after patch
					if l_todo.title.is_empty then
						send_error (res, 400, "Title cannot be empty")
					elseif l_todo.priority < 1 or l_todo.priority > 5 then
						send_error (res, 400, "Priority must be 1-5")
					else
						if todo_app.repository.update (l_todo) then
							res.send_json_object (todo_to_json (l_todo))
						else
							send_error (res, 500, "Failed to update todo")
						end
					end
				end
			end
		end

	handle_delete_todo (req: SIMPLE_WEB_SERVER_REQUEST; res: SIMPLE_WEB_SERVER_RESPONSE)
			-- DELETE /api/todos/{id} - Delete a todo.
		local
			l_id_param: detachable STRING_32
		do
			l_id_param := req.path_parameter ("id")

			if attached l_id_param as id_str and then id_str.is_integer_64 then
				if todo_app.delete_todo (id_str.to_integer_64) then
					res.set_no_content
					res.send_empty
				else
					send_error (res, 404, "Todo not found")
				end
			else
				send_error (res, 400, "Invalid todo ID")
			end
		end

feature {NONE} -- Handlers: Actions

	handle_complete_todo (req: SIMPLE_WEB_SERVER_REQUEST; res: SIMPLE_WEB_SERVER_RESPONSE)
			-- POST /api/todos/{id}/complete - Mark as completed.
		local
			l_id_param: detachable STRING_32
		do
			l_id_param := req.path_parameter ("id")

			if attached l_id_param as id_str and then id_str.is_integer_64 then
				if todo_app.complete_todo (id_str.to_integer_64) then
					if attached todo_app.find_todo (id_str.to_integer_64) as l_todo then
						res.send_json_object (todo_to_json (l_todo))
					else
						send_error (res, 500, "Todo updated but not found")
					end
				else
					send_error (res, 404, "Todo not found")
				end
			else
				send_error (res, 400, "Invalid todo ID")
			end
		end

	handle_incomplete_todo (req: SIMPLE_WEB_SERVER_REQUEST; res: SIMPLE_WEB_SERVER_RESPONSE)
			-- POST /api/todos/{id}/incomplete - Mark as incomplete.
		local
			l_id_param: detachable STRING_32
		do
			l_id_param := req.path_parameter ("id")

			if attached l_id_param as id_str and then id_str.is_integer_64 then
				if todo_app.uncomplete_todo (id_str.to_integer_64) then
					if attached todo_app.find_todo (id_str.to_integer_64) as l_todo then
						res.send_json_object (todo_to_json (l_todo))
					else
						send_error (res, 500, "Todo updated but not found")
					end
				else
					send_error (res, 404, "Todo not found")
				end
			else
				send_error (res, 400, "Invalid todo ID")
			end
		end

	handle_clear_completed (req: SIMPLE_WEB_SERVER_REQUEST; res: SIMPLE_WEB_SERVER_RESPONSE)
			-- DELETE /api/todos/completed - Delete all completed todos.
		local
			l_count: INTEGER
			l_json: SIMPLE_JSON_OBJECT
		do
			l_count := todo_app.clear_completed
			create l_json.make
			l_json.put_boolean (True, "success").do_nothing
			l_json.put_integer (l_count.to_integer_64, "deleted_count").do_nothing
			res.send_json_object (l_json)
		end

feature {NONE} -- Handlers: Stats

	handle_stats (req: SIMPLE_WEB_SERVER_REQUEST; res: SIMPLE_WEB_SERVER_RESPONSE)
			-- GET /api/stats - Todo statistics.
		local
			l_json: SIMPLE_JSON_OBJECT
		do
			create l_json.make
			l_json.put_integer (todo_app.total_count.to_integer_64, "total").do_nothing
			l_json.put_integer (todo_app.incomplete_count.to_integer_64, "incomplete").do_nothing
			l_json.put_integer (todo_app.completed_count.to_integer_64, "completed").do_nothing
			l_json.put_integer (todo_app.overdue_count.to_integer_64, "overdue").do_nothing
			l_json.put_real (todo_app.completion_percentage, "completion_percentage").do_nothing
			res.send_json_object (l_json)
		end

feature {NONE} -- JSON Conversion

	todo_to_json (a_todo: TODO_ITEM): SIMPLE_JSON_OBJECT
			-- Convert TODO_ITEM to JSON object.
			-- [F1] FRICTION: This should be on TODO_ITEM itself as to_json
		do
			create Result.make
			Result.put_integer (a_todo.id, "id").do_nothing
			Result.put_string (a_todo.title, "title").do_nothing
			if attached a_todo.description as d then
				Result.put_string (d, "description").do_nothing
			else
				Result.put_null ("description").do_nothing
			end
			Result.put_integer (a_todo.priority.to_integer_64, "priority").do_nothing
			Result.put_boolean (a_todo.is_completed, "is_completed").do_nothing
			if attached a_todo.due_date as dd then
				Result.put_string (dd, "due_date").do_nothing
			else
				Result.put_null ("due_date").do_nothing
			end
			Result.put_string (a_todo.created_at, "created_at").do_nothing
			Result.put_string (a_todo.updated_at, "updated_at").do_nothing
		end

	apply_json_to_todo (a_todo: TODO_ITEM; a_json: SIMPLE_JSON_OBJECT)
			-- Apply JSON fields to existing TODO_ITEM (full update).
			-- Note: If TODO_ITEM inherited SIMPLE_JSON_SERIALIZABLE, this would be
			-- a_todo.apply_json (a_json) - a single call.
		require
			-- [F3] FRICTIONLESS: Single precondition check
			has_required: a_json.has_all_keys (<<"title", "priority">>)
		do
			if attached a_json.string_item ("title") as t then
				a_todo.set_title (t.to_string_8)
			end

			-- [F4] FRICTIONLESS: Direct INTEGER_32 extraction
			a_todo.set_priority (a_json.integer_32_item ("priority"))

			-- [F5] FRICTIONLESS: Optional fields with single call
			if attached a_json.optional_string ("description") as d then
				a_todo.set_description (d.to_string_8)
			else
				a_todo.set_description (Void)
			end

			if attached a_json.optional_string ("due_date") as dd then
				a_todo.set_due_date (dd.to_string_8)
			else
				a_todo.set_due_date (Void)
			end

			if a_json.has_key ("is_completed") then
				if a_json.boolean_item ("is_completed") then
					a_todo.mark_completed
				else
					a_todo.mark_incomplete
				end
			end
		end

	apply_json_patch_to_todo (a_todo: TODO_ITEM; a_json: SIMPLE_JSON_OBJECT)
			-- Apply only provided JSON fields to TODO_ITEM (partial update).
			-- Note: PATCH inherently requires checking each field - this is unavoidable complexity.
		do
			if a_json.has_key ("title") then
				if attached a_json.string_item ("title") as t then
					a_todo.set_title (t.to_string_8)
				end
			end

			if a_json.has_key ("priority") then
				-- [F4] FRICTIONLESS: Direct INTEGER_32 extraction
				a_todo.set_priority (a_json.integer_32_item ("priority"))
			end

			-- [F5] Note: For PATCH, we can't use optional_string directly because
			-- we need to distinguish between "key not present" (don't change) and
			-- "key present with null" (set to Void). This is inherent PATCH complexity.
			if a_json.has_key ("description") then
				if attached a_json.string_item ("description") as d then
					a_todo.set_description (d.to_string_8)
				else
					a_todo.set_description (Void)
				end
			end

			if a_json.has_key ("due_date") then
				if attached a_json.string_item ("due_date") as dd then
					a_todo.set_due_date (dd.to_string_8)
				else
					a_todo.set_due_date (Void)
				end
			end

			if a_json.has_key ("is_completed") then
				if a_json.boolean_item ("is_completed") then
					a_todo.mark_completed
				else
					a_todo.mark_incomplete
				end
			end
		end

feature {NONE} -- Helpers

	send_error (a_res: SIMPLE_WEB_SERVER_RESPONSE; a_status: INTEGER; a_message: STRING)
			-- Send JSON error response.
			-- Note: simple_web now has send_error convenience method but we need
			-- consistent format with "success" field
		local
			l_json: SIMPLE_JSON_OBJECT
		do
			create l_json.make
			l_json.put_boolean (False, "success").do_nothing
			l_json.put_string (a_message, "error").do_nothing
			l_json.put_integer (a_status.to_integer_64, "status").do_nothing
			a_res.set_status (a_status)
			a_res.send_json_object (l_json)
		end

invariant
	server_attached: server /= Void
	todo_app_attached: todo_app /= Void

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
