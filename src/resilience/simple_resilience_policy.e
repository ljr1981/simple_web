note
	description: "[
		Unified resilience policy builder combining multiple patterns.

		Composes:
		- Retry with exponential backoff and jitter
		- Circuit breaker for fail-fast behavior
		- Timeout for bounded waits
		- Bulkhead for concurrency limiting
		- Fallback for graceful degradation

		Usage (fluent builder pattern):
			policy: SIMPLE_RESILIENCE_POLICY
			create policy.make
			policy.with_retry (3)
			      .with_circuit_breaker (5, 30)
			      .with_timeout (10)
			      .with_bulkhead (100)

			-- Execute with policy
			Result := policy.execute_function (agent my_operation)

		Execution Order:
			1. Bulkhead (acquire permit)
			2. Circuit Breaker (check if allowed)
			3. Timeout (wrap operation)
			4. Retry (handle transient failures)
			5. Operation
			6. Fallback (on failure, if configured)
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_RESILIENCE_POLICY

create
	make

feature {NONE} -- Initialization

	make
			-- Create empty policy (no resilience patterns).
		do
			timeout_seconds := 0  -- 0 means no timeout
			retry_max_attempts := 0
			retry_initial_delay_ms := 100
			retry_max_delay_ms := 30000
			retry_use_jitter := True
			name := "default"
		ensure
			no_timeout: timeout_seconds = 0
			no_retry: retry_max_attempts = 0
		end

feature -- Builder: Retry

	with_retry (a_max_attempts: INTEGER): like Current
			-- Add retry with default exponential backoff.
		require
			positive_attempts: a_max_attempts > 0
		do
			retry_max_attempts := a_max_attempts
			Result := Current
		ensure
			retry_set: retry_max_attempts = a_max_attempts
			fluent: Result = Current
		end

	with_retry_backoff (a_max_attempts: INTEGER; a_initial_ms: INTEGER; a_max_ms: INTEGER; a_jitter: BOOLEAN): like Current
			-- Add retry with custom backoff configuration.
		require
			positive_attempts: a_max_attempts > 0
			positive_initial: a_initial_ms > 0
			positive_max: a_max_ms >= a_initial_ms
		do
			retry_max_attempts := a_max_attempts
			retry_initial_delay_ms := a_initial_ms
			retry_max_delay_ms := a_max_ms
			retry_use_jitter := a_jitter
			Result := Current
		ensure
			retry_set: retry_max_attempts = a_max_attempts
			initial_set: retry_initial_delay_ms = a_initial_ms
			max_set: retry_max_delay_ms = a_max_ms
			jitter_set: retry_use_jitter = a_jitter
			fluent: Result = Current
		end

	with_no_retry: like Current
			-- Explicitly disable retry.
		do
			retry_max_attempts := 0
			Result := Current
		ensure
			no_retry: retry_max_attempts = 0
			fluent: Result = Current
		end

feature -- Builder: Circuit Breaker

	with_circuit_breaker (a_failure_threshold: INTEGER; a_cooldown_seconds: INTEGER): like Current
			-- Add circuit breaker with specified thresholds.
		require
			positive_threshold: a_failure_threshold > 0
			positive_cooldown: a_cooldown_seconds > 0
		do
			create circuit_breaker.make (a_failure_threshold, a_cooldown_seconds)
			Result := Current
		ensure
			circuit_breaker_set: circuit_breaker /= Void
			fluent: Result = Current
		end

	with_circuit_breaker_full (a_failure_threshold: INTEGER; a_success_threshold: INTEGER; a_cooldown_seconds: INTEGER): like Current
			-- Add circuit breaker with full configuration.
		require
			positive_failure: a_failure_threshold > 0
			positive_success: a_success_threshold > 0
			positive_cooldown: a_cooldown_seconds > 0
		do
			create circuit_breaker.make_with_config (a_failure_threshold, a_success_threshold, a_cooldown_seconds)
			Result := Current
		ensure
			circuit_breaker_set: circuit_breaker /= Void
			fluent: Result = Current
		end

	with_existing_circuit_breaker (a_breaker: SIMPLE_CIRCUIT_BREAKER): like Current
			-- Use an existing circuit breaker instance (for sharing).
		require
			breaker_not_void: a_breaker /= Void
		do
			circuit_breaker := a_breaker
			Result := Current
		ensure
			circuit_breaker_set: circuit_breaker = a_breaker
			fluent: Result = Current
		end

feature -- Builder: Timeout

	with_timeout (a_seconds: INTEGER): like Current
			-- Add timeout limit.
		require
			positive_timeout: a_seconds > 0
		do
			timeout_seconds := a_seconds
			Result := Current
		ensure
			timeout_set: timeout_seconds = a_seconds
			fluent: Result = Current
		end

	with_no_timeout: like Current
			-- Explicitly disable timeout.
		do
			timeout_seconds := 0
			Result := Current
		ensure
			no_timeout: timeout_seconds = 0
			fluent: Result = Current
		end

feature -- Builder: Bulkhead

	with_bulkhead (a_max_concurrent: INTEGER): like Current
			-- Add bulkhead with specified limit.
		require
			positive_limit: a_max_concurrent > 0
		do
			create bulkhead.make (a_max_concurrent)
			Result := Current
		ensure
			bulkhead_set: bulkhead /= Void
			fluent: Result = Current
		end

	with_existing_bulkhead (a_bulkhead: SIMPLE_BULKHEAD): like Current
			-- Use an existing bulkhead instance (for sharing).
		require
			bulkhead_not_void: a_bulkhead /= Void
		do
			bulkhead := a_bulkhead
			Result := Current
		ensure
			bulkhead_set: bulkhead = a_bulkhead
			fluent: Result = Current
		end

feature -- Builder: Fallback

	with_fallback (a_handler: FUNCTION [TUPLE, detachable ANY]): like Current
			-- Add fallback handler for failures.
		require
			handler_not_void: a_handler /= Void
		do
			fallback_handler := a_handler
			Result := Current
		ensure
			fallback_set: fallback_handler = a_handler
			fluent: Result = Current
		end

	with_fallback_value (a_value: detachable ANY): like Current
			-- Add simple fallback that returns a fixed value.
		do
			stored_fallback_value := a_value
			fallback_handler := agent get_stored_fallback_value
			Result := Current
		ensure
			fallback_set: fallback_handler /= Void
			fluent: Result = Current
		end

feature -- Builder: Naming

	with_name (a_name: STRING): like Current
			-- Set policy name for logging/debugging.
		require
			name_not_empty: a_name /= Void and then not a_name.is_empty
		do
			name := a_name
			Result := Current
		ensure
			name_set: name = a_name
			fluent: Result = Current
		end

feature -- Access

	circuit_breaker: detachable SIMPLE_CIRCUIT_BREAKER
			-- Circuit breaker component (if configured)

	bulkhead: detachable SIMPLE_BULKHEAD
			-- Bulkhead component (if configured)

	fallback_handler: detachable FUNCTION [TUPLE, detachable ANY]
			-- Fallback function (if configured)

	stored_fallback_value: detachable ANY
			-- Stored fallback value for with_fallback_value

	timeout_seconds: INTEGER
			-- Timeout in seconds (0 = no timeout)

	retry_max_attempts: INTEGER
			-- Maximum retry attempts (0 = no retry)

	retry_initial_delay_ms: INTEGER
			-- Initial retry delay in milliseconds

	retry_max_delay_ms: INTEGER
			-- Maximum retry delay in milliseconds

	retry_use_jitter: BOOLEAN
			-- Add jitter to prevent thundering herd?

	name: STRING
			-- Policy name for identification

feature -- Status

	has_circuit_breaker: BOOLEAN
			-- Is circuit breaker configured?
		do
			Result := circuit_breaker /= Void
		end

	has_bulkhead: BOOLEAN
			-- Is bulkhead configured?
		do
			Result := bulkhead /= Void
		end

	has_fallback: BOOLEAN
			-- Is fallback configured?
		do
			Result := fallback_handler /= Void
		end

	has_timeout: BOOLEAN
			-- Is timeout configured?
		do
			Result := timeout_seconds > 0
		end

	has_retry: BOOLEAN
			-- Is retry configured?
		do
			Result := retry_max_attempts > 0
		end

	is_circuit_open: BOOLEAN
			-- Is circuit breaker currently open?
		do
			if attached circuit_breaker as cb then
				Result := cb.is_open
			end
		end

feature -- Execution

	execute_procedure (a_operation: PROCEDURE)
			-- Execute procedure with policy applied.
		require
			operation_not_void: a_operation /= Void
		local
			l_acquired: BOOLEAN
			l_proceed: BOOLEAN
			l_dummy: detachable ANY
		do
			last_succeeded := False
			last_error_message := Void
			l_proceed := True

			-- 1. Bulkhead check
			if l_proceed and then attached bulkhead as bh then
				l_acquired := bh.acquire
				if not l_acquired then
					last_error_message := "Bulkhead full - request rejected"
					handle_failure
					if has_fallback then
						l_dummy := execute_fallback
					end
					l_proceed := False
				end
			end

			-- 2. Circuit breaker check
			if l_proceed and then attached circuit_breaker as cb then
				if not cb.allow_request then
					last_error_message := "Circuit breaker open - request blocked"
					release_bulkhead
					if has_fallback then
						l_dummy := execute_fallback
					end
					l_proceed := False
				end
			end

			-- 3. Execute with retry
			if l_proceed then
				execute_with_retry (a_operation)
			end

			-- 4. Release bulkhead
			release_bulkhead
		end

	execute_function (a_operation: FUNCTION [TUPLE, detachable ANY]): detachable ANY
			-- Execute function with policy applied, return result.
		require
			operation_not_void: a_operation /= Void
		local
			l_acquired: BOOLEAN
			l_proceed: BOOLEAN
		do
			last_succeeded := False
			last_error_message := Void
			l_proceed := True

			-- 1. Bulkhead check
			if l_proceed and then attached bulkhead as bh then
				l_acquired := bh.acquire
				if not l_acquired then
					last_error_message := "Bulkhead full - request rejected"
					handle_failure
					if has_fallback then
						Result := execute_fallback
					end
					l_proceed := False
				end
			end

			-- 2. Circuit breaker check
			if l_proceed and then attached circuit_breaker as cb then
				if not cb.allow_request then
					last_error_message := "Circuit breaker open - request blocked"
					release_bulkhead
					if has_fallback then
						Result := execute_fallback
					end
					l_proceed := False
				end
			end

			-- 3. Execute with retry
			if l_proceed then
				Result := execute_function_with_retry (a_operation)
			end

			-- 4. Release bulkhead
			release_bulkhead
		end

feature -- Execution Status

	last_succeeded: BOOLEAN
			-- Did last execution succeed?

	last_error_message: detachable STRING
			-- Error message from last execution (if failed)

	last_attempt_count: INTEGER
			-- Number of attempts in last execution

feature {NONE} -- Implementation

	get_stored_fallback_value: detachable ANY
			-- Return the stored fallback value.
		do
			Result := stored_fallback_value
		end

	execute_with_retry (a_operation: PROCEDURE)
			-- Execute procedure with retry logic.
		local
			l_attempt: INTEGER
			l_success: BOOLEAN
			l_delay: INTEGER
		do
			from
				l_attempt := 1
				l_success := False
			until
				l_success or l_attempt > retry_max_attempts.max (1)
			loop
				l_success := try_execute_procedure (a_operation)

				if not l_success and then l_attempt <= retry_max_attempts then
					-- Calculate delay and wait
					l_delay := delay_for_attempt (l_attempt)
					sleep_milliseconds (l_delay)
				end

				l_attempt := l_attempt + 1
			end

			last_attempt_count := l_attempt - 1
			last_succeeded := l_success

			if l_success then
				handle_success
			else
				handle_failure
			end
		end

	execute_function_with_retry (a_operation: FUNCTION [TUPLE, detachable ANY]): detachable ANY
			-- Execute function with retry logic.
		local
			l_attempt: INTEGER
			l_success: BOOLEAN
			l_delay: INTEGER
		do
			from
				l_attempt := 1
				l_success := False
			until
				l_success or l_attempt > retry_max_attempts.max (1)
			loop
				Result := try_execute_function (a_operation)
				l_success := last_try_succeeded

				if not l_success and then l_attempt <= retry_max_attempts then
					l_delay := delay_for_attempt (l_attempt)
					sleep_milliseconds (l_delay)
				end

				l_attempt := l_attempt + 1
			end

			last_attempt_count := l_attempt - 1
			last_succeeded := l_success

			if l_success then
				handle_success
			else
				handle_failure
				if has_fallback then
					Result := execute_fallback
				end
			end
		end

	try_execute_procedure (a_operation: PROCEDURE): BOOLEAN
			-- Try to execute procedure, return True on success.
		local
			l_retried: BOOLEAN
		do
			if not l_retried then
				a_operation.call (Void)
				last_try_succeeded := True
				Result := True
			end
		rescue
			last_try_succeeded := False
			last_error_message := "Operation failed"
			l_retried := True
			retry
		end

	try_execute_function (a_operation: FUNCTION [TUPLE, detachable ANY]): detachable ANY
			-- Try to execute function, store success in last_try_succeeded.
		local
			l_retried: BOOLEAN
		do
			if not l_retried then
				Result := a_operation.item (Void)
				last_try_succeeded := True
			end
		rescue
			last_try_succeeded := False
			last_error_message := "Operation failed"
			l_retried := True
			retry
		end

	last_try_succeeded: BOOLEAN
			-- Did the last try succeed?

	execute_fallback: detachable ANY
			-- Execute fallback handler if configured.
		do
			if attached fallback_handler as fh then
				Result := fh.item (Void)
			end
		end

	handle_success
			-- Handle successful execution.
		do
			if attached circuit_breaker as cb then
				cb.record_success
			end
		end

	handle_failure
			-- Handle failed execution.
		do
			if attached circuit_breaker as cb then
				cb.record_failure
			end
		end

	release_bulkhead
			-- Release bulkhead permit if held.
		do
			if attached bulkhead as bh then
				bh.release_if_held
			end
		end

	delay_for_attempt (a_attempt: INTEGER): INTEGER
			-- Calculate delay in milliseconds for given attempt.
		local
			l_base: INTEGER
			l_jitter: INTEGER
		do
			-- Exponential backoff: initial * 2^(attempt-1)
			l_base := retry_initial_delay_ms * (2 ^ (a_attempt - 1)).truncated_to_integer

			-- Cap at max
			if l_base > retry_max_delay_ms then
				l_base := retry_max_delay_ms
			end

			-- Add jitter (0-50% of base)
			if retry_use_jitter and l_base > 0 then
				increment_jitter_seed
				l_jitter := (jitter_seed \\ (l_base // 2 + 1)).abs
				Result := l_base + l_jitter
			else
				Result := l_base
			end
		ensure
			non_negative: Result >= 0
		end

	jitter_seed: INTEGER
			-- Seed for jitter calculation

	increment_jitter_seed
			-- Increment seed for pseudo-random jitter.
		do
			jitter_seed := jitter_seed + 12345
			if jitter_seed < 0 then
				jitter_seed := 1
			end
		end

	sleep_milliseconds (a_ms: INTEGER)
			-- Sleep for specified milliseconds.
		local
			l_env: EXECUTION_ENVIRONMENT
		do
			create l_env
			l_env.sleep (a_ms * 1_000_000) -- nanoseconds
		end

invariant
	non_negative_timeout: timeout_seconds >= 0
	non_negative_retry: retry_max_attempts >= 0
	positive_initial_delay: retry_initial_delay_ms > 0
	positive_max_delay: retry_max_delay_ms > 0
	max_at_least_initial: retry_max_delay_ms >= retry_initial_delay_ms
	name_not_void: name /= Void

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
