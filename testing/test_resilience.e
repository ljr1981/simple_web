note
	description: "Tests for resilience patterns (circuit breaker, bulkhead, policy)"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_RESILIENCE

inherit
	TEST_SET_BASE

feature -- Circuit Breaker Tests

	test_circuit_breaker_initial_state
			-- Circuit breaker starts closed.
		local
			cb: SIMPLE_CIRCUIT_BREAKER
		do
			create cb.make (5, 30)
			assert_true ("initial state is closed", cb.is_closed)
			assert_false ("not open", cb.is_open)
			assert_false ("not half-open", cb.is_half_open)
			assert_true ("allows requests", cb.allow_request)
		end

	test_circuit_breaker_opens_after_threshold
			-- Circuit opens after failure threshold.
		local
			cb: SIMPLE_CIRCUIT_BREAKER
			i: INTEGER
		do
			create cb.make (3, 30)  -- Opens after 3 failures

			-- Record 3 failures
			from i := 1 until i > 3 loop
				cb.record_failure
				i := i + 1
			end

			assert_true ("circuit is now open", cb.is_open)
			assert_false ("request not allowed", cb.allow_request)
		end

	test_circuit_breaker_success_resets_count
			-- Success resets failure count in closed state.
		local
			cb: SIMPLE_CIRCUIT_BREAKER
		do
			create cb.make (5, 30)

			cb.record_failure
			cb.record_failure
			assert_integers_equal ("two failures", 2, cb.failure_count)

			cb.record_success
			assert_integers_equal ("failures reset", 0, cb.failure_count)
			assert_true ("still closed", cb.is_closed)
		end

	test_circuit_breaker_state_name
			-- State name returns correct string.
		local
			cb: SIMPLE_CIRCUIT_BREAKER
		do
			create cb.make (2, 30)
			assert_strings_equal ("closed name", "CLOSED", cb.state_name)

			cb.record_failure
			cb.record_failure
			assert_strings_equal ("open name", "OPEN", cb.state_name)
		end

	test_circuit_breaker_force_open
			-- Force open works.
		local
			cb: SIMPLE_CIRCUIT_BREAKER
		do
			create cb.make (5, 30)
			assert_true ("starts closed", cb.is_closed)

			cb.force_open
			assert_true ("now open", cb.is_open)
		end

	test_circuit_breaker_force_closed
			-- Force closed works.
		local
			cb: SIMPLE_CIRCUIT_BREAKER
		do
			create cb.make (2, 30)
			cb.record_failure
			cb.record_failure
			assert_true ("is open", cb.is_open)

			cb.force_closed
			assert_true ("now closed", cb.is_closed)
			assert_integers_equal ("counts reset", 0, cb.failure_count)
		end

	test_circuit_breaker_reset
			-- Reset restores initial state.
		local
			cb: SIMPLE_CIRCUIT_BREAKER
		do
			create cb.make (2, 30)
			cb.record_failure
			cb.record_failure
			assert_true ("is open", cb.is_open)

			cb.reset
			assert_true ("is closed after reset", cb.is_closed)
			assert_integers_equal ("failure count reset", 0, cb.failure_count)
			assert_integers_equal ("success count reset", 0, cb.success_count)
		end

feature -- Bulkhead Tests

	test_bulkhead_initial_state
			-- Bulkhead starts empty.
		local
			bh: SIMPLE_BULKHEAD
		do
			create bh.make (10)
			assert_false ("not full", bh.is_full)
			assert_integers_equal ("none concurrent", 0, bh.current_concurrent)
			assert_integers_equal ("10 available", 10, bh.available_permits)
		end

	test_bulkhead_acquire_release
			-- Acquire and release work correctly.
		local
			bh: SIMPLE_BULKHEAD
			acquired: BOOLEAN
		do
			create bh.make (3)

			acquired := bh.acquire
			assert_true ("acquired first", acquired)
			assert_integers_equal ("1 concurrent", 1, bh.current_concurrent)

			acquired := bh.acquire
			assert_true ("acquired second", acquired)
			assert_integers_equal ("2 concurrent", 2, bh.current_concurrent)

			bh.release
			assert_integers_equal ("1 concurrent after release", 1, bh.current_concurrent)

			bh.release
			assert_integers_equal ("0 concurrent after second release", 0, bh.current_concurrent)
		end

	test_bulkhead_rejects_when_full
			-- Bulkhead rejects when at capacity.
		local
			bh: SIMPLE_BULKHEAD
			acquired: BOOLEAN
		do
			create bh.make (2)

			acquired := bh.acquire
			assert_true ("first acquired", acquired)

			acquired := bh.acquire
			assert_true ("second acquired", acquired)

			assert_true ("bulkhead is full", bh.is_full)

			acquired := bh.acquire
			assert_false ("third rejected", acquired)
			assert_integers_equal ("still 2 concurrent", 2, bh.current_concurrent)
		end

	test_bulkhead_utilization
			-- Utilization percentage calculated correctly.
		local
			bh: SIMPLE_BULKHEAD
			l_ok: BOOLEAN
		do
			create bh.make (4)

			assert_real_equal ("0%% utilized", 0.0, bh.utilization_percent)

			l_ok := bh.acquire
			l_ok := bh.acquire
			assert_real_equal ("50%% utilized", 50.0, bh.utilization_percent)

			l_ok := bh.acquire
			l_ok := bh.acquire
			assert_real_equal ("100%% utilized", 100.0, bh.utilization_percent)
		end

	test_bulkhead_statistics
			-- Statistics tracking works.
		local
			bh: SIMPLE_BULKHEAD
			l_ok: BOOLEAN
		do
			create bh.make (2)

			l_ok := bh.acquire
			l_ok := bh.acquire
			l_ok := bh.acquire  -- rejected
			l_ok := bh.acquire  -- rejected

			assert_integers_equal ("2 acquired", 2, bh.total_acquired.to_integer_32)
			assert_integers_equal ("2 rejected", 2, bh.total_rejected.to_integer_32)
			assert_real_equal ("50%% rejection rate", 50.0, bh.rejection_rate)
		end

	test_bulkhead_release_if_held
			-- Release_if_held is safe when no permit held.
		local
			bh: SIMPLE_BULKHEAD
		do
			create bh.make (5)
			-- Should not crash even with no permits held
			bh.release_if_held
			assert_integers_equal ("still 0", 0, bh.current_concurrent)
		end

feature -- Policy Tests

	test_policy_default_state
			-- Default policy has nothing configured.
		local
			policy: SIMPLE_RESILIENCE_POLICY
		do
			create policy.make
			assert_false ("no circuit breaker", policy.has_circuit_breaker)
			assert_false ("no bulkhead", policy.has_bulkhead)
			assert_false ("no fallback", policy.has_fallback)
			assert_false ("no timeout", policy.has_timeout)
			assert_false ("no retry", policy.has_retry)
		end

	test_policy_builder_fluent
			-- Builder pattern returns same instance.
		local
			policy: SIMPLE_RESILIENCE_POLICY
		do
			create policy.make
			assert_true ("fluent retry", policy.with_retry (3) = policy)
			assert_true ("fluent circuit breaker", policy.with_circuit_breaker (5, 30) = policy)
			assert_true ("fluent timeout", policy.with_timeout (10) = policy)
			assert_true ("fluent bulkhead", policy.with_bulkhead (100) = policy)
		end

	test_policy_with_retry
			-- Retry configuration works.
		local
			policy: SIMPLE_RESILIENCE_POLICY
			l_dummy: SIMPLE_RESILIENCE_POLICY
		do
			create policy.make
			l_dummy := policy.with_retry (5)

			assert_true ("has retry", policy.has_retry)
			assert_integers_equal ("max retries", 5, policy.retry_max_attempts)
		end

	test_policy_with_circuit_breaker
			-- Circuit breaker configuration works.
		local
			policy: SIMPLE_RESILIENCE_POLICY
			l_dummy: SIMPLE_RESILIENCE_POLICY
		do
			create policy.make
			l_dummy := policy.with_circuit_breaker (10, 60)

			assert_true ("has circuit breaker", policy.has_circuit_breaker)
			assert_false ("circuit not open", policy.is_circuit_open)
		end

	test_policy_with_bulkhead
			-- Bulkhead configuration works.
		local
			policy: SIMPLE_RESILIENCE_POLICY
			l_dummy: SIMPLE_RESILIENCE_POLICY
		do
			create policy.make
			l_dummy := policy.with_bulkhead (50)

			assert_true ("has bulkhead", policy.has_bulkhead)
		end

	test_policy_with_timeout
			-- Timeout configuration works.
		local
			policy: SIMPLE_RESILIENCE_POLICY
			l_dummy: SIMPLE_RESILIENCE_POLICY
		do
			create policy.make
			l_dummy := policy.with_timeout (30)

			assert_true ("has timeout", policy.has_timeout)
			assert_integers_equal ("timeout value", 30, policy.timeout_seconds)
		end

	test_policy_with_fallback_value
			-- Fallback value configuration works.
		local
			policy: SIMPLE_RESILIENCE_POLICY
			l_dummy: SIMPLE_RESILIENCE_POLICY
		do
			create policy.make
			l_dummy := policy.with_fallback_value ("default")

			assert_true ("has fallback", policy.has_fallback)
		end

	test_policy_execute_success
			-- Successful execution recorded correctly.
		local
			policy: SIMPLE_RESILIENCE_POLICY
			result_value: detachable ANY
			l_dummy: SIMPLE_RESILIENCE_POLICY
		do
			create policy.make
			l_dummy := policy.with_circuit_breaker (5, 30)

			result_value := policy.execute_function (agent successful_operation)

			assert_true ("execution succeeded", policy.last_succeeded)
			if attached {STRING} result_value as s then
				assert_strings_equal ("correct result", "success", s)
			else
				assert_true ("result is string", False)
			end
		end

	test_policy_execute_with_retry
			-- Retry executes multiple times on failure.
		local
			policy: SIMPLE_RESILIENCE_POLICY
			l_dummy: SIMPLE_RESILIENCE_POLICY
		do
			create policy.make
			l_dummy := policy.with_retry_backoff (3, 10, 100, False)  -- Fast retry for testing

			attempt_counter := 0
			policy.execute_procedure (agent failing_then_succeeding_operation)

			assert_integers_equal ("attempted 2 times", 2, attempt_counter)
		end

feature {NONE} -- Test Helpers

	successful_operation: STRING
			-- Operation that succeeds.
		do
			Result := "success"
		end

	attempt_counter: INTEGER
			-- Counter for retry tests

	failing_then_succeeding_operation
			-- Operation that fails first time, succeeds second.
		do
			attempt_counter := attempt_counter + 1
			if attempt_counter < 2 then
				(create {DEVELOPER_EXCEPTION}).raise
			end
		end

	assert_real_equal (a_tag: STRING; expected, actual: REAL_64)
			-- Assert two reals are equal (within tolerance).
		do
			assert_true (a_tag, (expected - actual).abs < 0.01)
		end

end
