note
	description: "[
		Circuit breaker pattern implementation for resilience.

		Prevents cascading failures by monitoring call success/failure rates
		and temporarily blocking calls to failing services.

		States:
		- Closed: Normal operation, calls allowed, failures monitored
		- Open: Circuit tripped, calls blocked, waiting for cooldown
		- Half-Open: Testing recovery, limited calls allowed

		Usage:
			breaker: SIMPLE_CIRCUIT_BREAKER
			create breaker.make (5, 30)  -- 5 failures, 30 second cooldown

			if breaker.allow_request then
				-- Make call
				if success then
					breaker.record_success
				else
					breaker.record_failure
				end
			else
				-- Use fallback or fail fast
			end
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"
	EIS: "name=Circuit Breaker Pattern", "protocol=URI", "src=https://martinfowler.com/bliki/CircuitBreaker.html"

class
	SIMPLE_CIRCUIT_BREAKER

create
	make,
	make_with_config

feature {NONE} -- Initialization

	make (a_failure_threshold: INTEGER; a_cooldown_seconds: INTEGER)
			-- Create circuit breaker with specified thresholds.
		require
			positive_threshold: a_failure_threshold > 0
			positive_cooldown: a_cooldown_seconds > 0
		do
			failure_threshold := a_failure_threshold
			cooldown_seconds := a_cooldown_seconds
			success_threshold := Default_success_threshold
			state := State_closed
			failure_count := 0
			success_count := 0
			create last_state_change.make_now
			create last_failure_time.make_now
		ensure
			closed: state = State_closed
			threshold_set: failure_threshold = a_failure_threshold
			cooldown_set: cooldown_seconds = a_cooldown_seconds
		end

	make_with_config (a_failure_threshold: INTEGER; a_success_threshold: INTEGER; a_cooldown_seconds: INTEGER)
			-- Create circuit breaker with full configuration.
		require
			positive_failure_threshold: a_failure_threshold > 0
			positive_success_threshold: a_success_threshold > 0
			positive_cooldown: a_cooldown_seconds > 0
		do
			failure_threshold := a_failure_threshold
			success_threshold := a_success_threshold
			cooldown_seconds := a_cooldown_seconds
			state := State_closed
			failure_count := 0
			success_count := 0
			create last_state_change.make_now
			create last_failure_time.make_now
		ensure
			closed: state = State_closed
			failure_threshold_set: failure_threshold = a_failure_threshold
			success_threshold_set: success_threshold = a_success_threshold
			cooldown_set: cooldown_seconds = a_cooldown_seconds
		end

feature -- State Constants

	State_closed: INTEGER = 0
			-- Normal operation - requests allowed

	State_open: INTEGER = 1
			-- Circuit tripped - requests blocked

	State_half_open: INTEGER = 2
			-- Recovery testing - limited requests allowed

feature -- Access

	state: INTEGER
			-- Current circuit breaker state

	failure_count: INTEGER
			-- Consecutive failures in closed state

	success_count: INTEGER
			-- Consecutive successes in half-open state

	failure_threshold: INTEGER
			-- Number of failures before opening circuit

	success_threshold: INTEGER
			-- Number of successes in half-open before closing

	cooldown_seconds: INTEGER
			-- Seconds to wait in open state before half-open

	last_state_change: SIMPLE_DATE_TIME
			-- When state last changed

	last_failure_time: SIMPLE_DATE_TIME
			-- When last failure occurred

feature -- Status

	is_closed: BOOLEAN
			-- Is circuit in closed (normal) state?
		do
			Result := state = State_closed
		end

	is_open: BOOLEAN
			-- Is circuit in open (blocking) state?
		do
			Result := state = State_open
		end

	is_half_open: BOOLEAN
			-- Is circuit in half-open (testing) state?
		do
			Result := state = State_half_open
		end

	state_name: STRING
			-- Human-readable state name
		do
			inspect state
			when State_closed then
				Result := "CLOSED"
			when State_open then
				Result := "OPEN"
			when State_half_open then
				Result := "HALF-OPEN"
			else
				Result := "UNKNOWN"
			end
		end

	allow_request: BOOLEAN
			-- Can a request proceed through the circuit?
		do
			inspect state
			when State_closed then
				-- Closed: always allow
				Result := True
			when State_open then
				-- Open: check if cooldown elapsed
				if is_cooldown_elapsed then
					transition_to_half_open
					Result := True
				else
					Result := False
				end
			when State_half_open then
				-- Half-open: allow (we're testing recovery)
				Result := True
			end
		end

	is_cooldown_elapsed: BOOLEAN
			-- Has the cooldown period elapsed since opening?
		local
			l_now: SIMPLE_DATE_TIME
			l_elapsed: INTEGER_64
		do
			create l_now.make_now
			l_elapsed := l_now.seconds_between (last_state_change)
			Result := l_elapsed >= cooldown_seconds
		end

	seconds_until_half_open: INTEGER
			-- Seconds remaining before transitioning to half-open (0 if not open)
		local
			l_now: SIMPLE_DATE_TIME
			l_elapsed: INTEGER_64
			l_remaining: INTEGER_64
		do
			if state = State_open then
				create l_now.make_now
				l_elapsed := l_now.seconds_between (last_state_change)
				l_remaining := cooldown_seconds - l_elapsed
				if l_remaining > 0 then
					Result := l_remaining.to_integer_32
				end
			end
		ensure
			non_negative: Result >= 0
		end

feature -- Operations

	record_success
			-- Record a successful call.
		do
			inspect state
			when State_closed then
				-- Success in closed state: reset failure count
				failure_count := 0
			when State_half_open then
				-- Success in half-open: count toward closing
				success_count := success_count + 1
				if success_count >= success_threshold then
					transition_to_closed
				end
			when State_open then
				-- Shouldn't happen (requests blocked), but handle gracefully
				-- Treat as signal to try half-open
				if is_cooldown_elapsed then
					transition_to_half_open
				end
			end
		ensure
			closed_resets_failures: old state = State_closed implies failure_count = 0
		end

	record_failure
			-- Record a failed call.
		do
			create last_failure_time.make_now
			inspect state
			when State_closed then
				-- Failure in closed state: increment and check threshold
				failure_count := failure_count + 1
				if failure_count >= failure_threshold then
					transition_to_open
				end
			when State_half_open then
				-- Failure in half-open: back to open
				transition_to_open
			when State_open then
				-- Already open, just update failure time
			end
		ensure
			threshold_opens: old state = State_closed and failure_count >= failure_threshold implies state = State_open
			half_open_failure_opens: old state = State_half_open implies state = State_open
		end

	reset
			-- Reset circuit breaker to closed state.
		do
			state := State_closed
			failure_count := 0
			success_count := 0
			create last_state_change.make_now
		ensure
			closed: state = State_closed
			counts_reset: failure_count = 0 and success_count = 0
		end

	force_open
			-- Force circuit to open state (manual intervention).
		do
			transition_to_open
		ensure
			open: state = State_open
		end

	force_closed
			-- Force circuit to closed state (manual intervention).
		do
			transition_to_closed
		ensure
			closed: state = State_closed
		end

feature {NONE} -- State Transitions

	transition_to_closed
			-- Transition to closed state.
		do
			state := State_closed
			failure_count := 0
			success_count := 0
			create last_state_change.make_now
		ensure
			closed: state = State_closed
			counts_reset: failure_count = 0 and success_count = 0
		end

	transition_to_open
			-- Transition to open state.
		do
			state := State_open
			success_count := 0
			create last_state_change.make_now
		ensure
			open: state = State_open
			success_reset: success_count = 0
		end

	transition_to_half_open
			-- Transition to half-open state.
		do
			state := State_half_open
			success_count := 0
			failure_count := 0
			create last_state_change.make_now
		ensure
			half_open: state = State_half_open
			counts_reset: failure_count = 0 and success_count = 0
		end

feature -- Constants

	Default_success_threshold: INTEGER = 3
			-- Default number of successes to close from half-open

invariant
	valid_state: state >= State_closed and state <= State_half_open
	positive_thresholds: failure_threshold > 0 and success_threshold > 0
	positive_cooldown: cooldown_seconds > 0
	non_negative_counts: failure_count >= 0 and success_count >= 0

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
