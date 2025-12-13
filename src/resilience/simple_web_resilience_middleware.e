note
	description: "[
		Resilience middleware for simple_web server pipeline.

		Wraps downstream handlers with resilience patterns:
		- Circuit breaker for downstream service protection
		- Bulkhead for concurrency limiting
		- Rate limiting integration

		Usage:
			router.use (create {SIMPLE_WEB_RESILIENCE_MIDDLEWARE}.make_with_policy (
				create {SIMPLE_RESILIENCE_POLICY}.make
					.with_circuit_breaker (10, 60)
					.with_bulkhead (100)
			))

		Or with named circuit breakers per endpoint:
			resilience_mw: SIMPLE_WEB_RESILIENCE_MIDDLEWARE
			create resilience_mw.make_default
			resilience_mw.add_endpoint_breaker ("/api/external", 5, 30)
			router.use (resilience_mw)
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_WEB_RESILIENCE_MIDDLEWARE

inherit
	SIMPLE_WEB_MIDDLEWARE

create
	make_default,
	make_with_policy,
	make_with_circuit_breaker,
	make_with_bulkhead

feature {NONE} -- Initialization

	make_default
			-- Create with no resilience patterns (pass-through).
		do
			create endpoint_breakers.make (10)
		ensure
			no_policy: policy = Void
			no_breakers: endpoint_breakers.is_empty
		end

	make_with_policy (a_policy: SIMPLE_RESILIENCE_POLICY)
			-- Create with a resilience policy.
		require
			policy_not_void: a_policy /= Void
		do
			policy := a_policy
			create endpoint_breakers.make (10)
		ensure
			policy_set: policy = a_policy
		end

	make_with_circuit_breaker (a_failure_threshold: INTEGER; a_cooldown_seconds: INTEGER)
			-- Create with just a circuit breaker.
		require
			positive_threshold: a_failure_threshold > 0
			positive_cooldown: a_cooldown_seconds > 0
		local
			l_policy: SIMPLE_RESILIENCE_POLICY
			l_dummy: SIMPLE_RESILIENCE_POLICY
		do
			create l_policy.make
			l_dummy := l_policy.with_circuit_breaker (a_failure_threshold, a_cooldown_seconds)
			policy := l_policy
			create endpoint_breakers.make (10)
		ensure
			policy_set: policy /= Void
		end

	make_with_bulkhead (a_max_concurrent: INTEGER)
			-- Create with just a bulkhead.
		require
			positive_limit: a_max_concurrent > 0
		local
			l_policy: SIMPLE_RESILIENCE_POLICY
			l_dummy: SIMPLE_RESILIENCE_POLICY
		do
			create l_policy.make
			l_dummy := l_policy.with_bulkhead (a_max_concurrent)
			policy := l_policy
			create endpoint_breakers.make (10)
		ensure
			policy_set: policy /= Void
		end

feature -- Access

	policy: detachable SIMPLE_RESILIENCE_POLICY
			-- Main resilience policy

	endpoint_breakers: HASH_TABLE [SIMPLE_CIRCUIT_BREAKER, STRING]
			-- Circuit breakers per endpoint pattern

	on_circuit_open: detachable PROCEDURE [TUPLE [path: STRING; breaker: SIMPLE_CIRCUIT_BREAKER]]
			-- Callback when circuit opens

	on_bulkhead_reject: detachable PROCEDURE [TUPLE [path: STRING]]
			-- Callback when bulkhead rejects

feature -- Configuration

	add_endpoint_breaker (a_path_pattern: STRING; a_failure_threshold: INTEGER; a_cooldown_seconds: INTEGER)
			-- Add circuit breaker for specific endpoint pattern.
		require
			pattern_not_empty: a_path_pattern /= Void and then not a_path_pattern.is_empty
			positive_threshold: a_failure_threshold > 0
			positive_cooldown: a_cooldown_seconds > 0
		local
			l_breaker: SIMPLE_CIRCUIT_BREAKER
		do
			create l_breaker.make (a_failure_threshold, a_cooldown_seconds)
			endpoint_breakers.force (l_breaker, a_path_pattern)
		ensure
			breaker_added: endpoint_breakers.has (a_path_pattern)
		end

	set_on_circuit_open (a_handler: PROCEDURE [TUPLE [path: STRING; breaker: SIMPLE_CIRCUIT_BREAKER]])
			-- Set callback for when circuit opens.
		do
			on_circuit_open := a_handler
		ensure
			handler_set: on_circuit_open = a_handler
		end

	set_on_bulkhead_reject (a_handler: PROCEDURE [TUPLE [path: STRING]])
			-- Set callback for bulkhead rejection.
		do
			on_bulkhead_reject := a_handler
		ensure
			handler_set: on_bulkhead_reject = a_handler
		end

feature -- Processing

	process (a_request: SIMPLE_WEB_SERVER_REQUEST; a_response: SIMPLE_WEB_SERVER_RESPONSE; a_next: PROCEDURE)
			-- Process request with resilience patterns.
		local
			l_breaker: detachable SIMPLE_CIRCUIT_BREAKER
			l_bulkhead_acquired: BOOLEAN
			l_proceed: BOOLEAN
			l_path: STRING
		do
			l_proceed := True
			l_path := a_request.path.to_string_8

			-- 1. Check endpoint-specific circuit breaker
			l_breaker := breaker_for_path (l_path)
			if l_proceed and then attached l_breaker as cb then
				if not cb.allow_request then
					-- Circuit is open - reject immediately
					respond_circuit_open (a_response, l_path)
					notify_circuit_open (l_path, cb)
					l_proceed := False
				end
			end

			-- 2. Check main policy circuit breaker
			if l_proceed and then attached policy as p then
				if p.has_circuit_breaker and then p.is_circuit_open then
					respond_circuit_open (a_response, l_path)
					l_proceed := False
				end

				-- 3. Check bulkhead
				if l_proceed and then attached p.bulkhead as bh then
					l_bulkhead_acquired := bh.acquire
					if not l_bulkhead_acquired then
						respond_bulkhead_full (a_response, l_path)
						notify_bulkhead_reject (l_path)
						l_proceed := False
					end
				end
			end

			-- 4. Execute downstream with success/failure tracking
			if l_proceed then
				execute_downstream (a_request, a_response, a_next, l_breaker)
			end

			-- 5. Release bulkhead
			if attached policy as p and then attached p.bulkhead as bh then
				bh.release_if_held
			end
		end

	name: STRING = "resilience"
			-- Middleware name

feature {NONE} -- Implementation

	breaker_for_path (a_path: STRING): detachable SIMPLE_CIRCUIT_BREAKER
			-- Find circuit breaker matching path.
		do
			from
				endpoint_breakers.start
			until
				endpoint_breakers.after or Result /= Void
			loop
				if a_path.starts_with (endpoint_breakers.key_for_iteration) then
					Result := endpoint_breakers.item_for_iteration
				end
				endpoint_breakers.forth
			end
		end

	execute_downstream (a_request: SIMPLE_WEB_SERVER_REQUEST; a_response: SIMPLE_WEB_SERVER_RESPONSE; a_next: PROCEDURE; a_breaker: detachable SIMPLE_CIRCUIT_BREAKER)
			-- Execute downstream and track success/failure.
		local
			l_retried: BOOLEAN
			l_original_status: INTEGER
		do
			if not l_retried then
				l_original_status := a_response.status_code

				-- Execute downstream
				a_next.call (Void)

				-- Check if downstream succeeded (2xx status)
				if is_success_status (a_response.status_code) then
					record_success (a_breaker)
				elseif is_server_error_status (a_response.status_code) then
					record_failure (a_breaker)
				end
			end
		rescue
			-- Exception in downstream - record failure
			record_failure (a_breaker)
			respond_internal_error (a_response)
			l_retried := True
			retry
		end

	record_success (a_breaker: detachable SIMPLE_CIRCUIT_BREAKER)
			-- Record success on breakers.
		do
			if attached a_breaker as cb then
				cb.record_success
			end
			if attached policy as p and then attached p.circuit_breaker as pcb then
				pcb.record_success
			end
		end

	record_failure (a_breaker: detachable SIMPLE_CIRCUIT_BREAKER)
			-- Record failure on breakers.
		do
			if attached a_breaker as cb then
				cb.record_failure
			end
			if attached policy as p and then attached p.circuit_breaker as pcb then
				pcb.record_failure
			end
		end

	is_success_status (a_status: INTEGER): BOOLEAN
			-- Is this a success status code (2xx)?
		do
			Result := a_status >= 200 and a_status < 300
		end

	is_server_error_status (a_status: INTEGER): BOOLEAN
			-- Is this a server error status (5xx)?
		do
			Result := a_status >= 500 and a_status < 600
		end

feature {NONE} -- Response Helpers

	respond_circuit_open (a_response: SIMPLE_WEB_SERVER_RESPONSE; a_path: STRING)
			-- Respond with 503 Service Unavailable when circuit is open.
		do
			a_response.set_status (503)
			a_response.set_header ("Retry-After", "30")
			a_response.send_json ("{%"error%":%"Service temporarily unavailable%",%"reason%":%"circuit_breaker_open%",%"path%":%"" + a_path + "%"}")
		end

	respond_bulkhead_full (a_response: SIMPLE_WEB_SERVER_RESPONSE; a_path: STRING)
			-- Respond with 503 when bulkhead is full.
		do
			a_response.set_status (503)
			a_response.set_header ("Retry-After", "5")
			a_response.send_json ("{%"error%":%"Service overloaded%",%"reason%":%"bulkhead_full%",%"path%":%"" + a_path + "%"}")
		end

	respond_internal_error (a_response: SIMPLE_WEB_SERVER_RESPONSE)
			-- Respond with 500 for unexpected errors.
		do
			a_response.set_status (500)
			a_response.send_json ("{%"error%":%"Internal server error%"}")
		end

feature {NONE} -- Notifications

	notify_circuit_open (a_path: STRING; a_breaker: SIMPLE_CIRCUIT_BREAKER)
			-- Notify that circuit opened.
		do
			if attached on_circuit_open as handler then
				handler.call ([a_path, a_breaker])
			end
		end

	notify_bulkhead_reject (a_path: STRING)
			-- Notify that bulkhead rejected request.
		do
			if attached on_bulkhead_reject as handler then
				handler.call ([a_path])
			end
		end

invariant
	endpoint_breakers_not_void: endpoint_breakers /= Void

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
