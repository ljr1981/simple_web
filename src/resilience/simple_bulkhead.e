note
	description: "[
		Bulkhead pattern implementation for resilience.

		Limits concurrent executions to prevent resource exhaustion.
		Like watertight compartments in a ship, isolates failures
		to prevent one overwhelmed service from consuming all resources.

		Usage:
			bulkhead: SIMPLE_BULKHEAD
			create bulkhead.make (10)  -- Max 10 concurrent calls

			if bulkhead.acquire then
				-- Execute protected operation
				bulkhead.release
			else
				-- Reject: too many concurrent calls
			end

		Thread Safety Note:
			For SCOOP environments, make bulkhead `separate` for
			automatic thread-safe access.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_BULKHEAD

create
	make,
	make_with_queue

feature {NONE} -- Initialization

	make (a_max_concurrent: INTEGER)
			-- Create bulkhead with max concurrent limit.
		require
			positive_limit: a_max_concurrent > 0
		do
			max_concurrent := a_max_concurrent
			max_queue := 0  -- No queuing by default
			current_concurrent := 0
			current_queued := 0
			total_acquired := 0
			total_rejected := 0
			name := "default"
		ensure
			limit_set: max_concurrent = a_max_concurrent
			no_queue: max_queue = 0
			empty: current_concurrent = 0
		end

	make_with_queue (a_max_concurrent: INTEGER; a_max_queue: INTEGER)
			-- Create bulkhead with concurrent limit and queue.
		require
			positive_concurrent: a_max_concurrent > 0
			non_negative_queue: a_max_queue >= 0
		do
			max_concurrent := a_max_concurrent
			max_queue := a_max_queue
			current_concurrent := 0
			current_queued := 0
			total_acquired := 0
			total_rejected := 0
			name := "default"
		ensure
			concurrent_set: max_concurrent = a_max_concurrent
			queue_set: max_queue = a_max_queue
			empty: current_concurrent = 0 and current_queued = 0
		end

feature -- Access

	max_concurrent: INTEGER
			-- Maximum concurrent executions allowed

	max_queue: INTEGER
			-- Maximum queued requests (0 = no queuing)

	current_concurrent: INTEGER
			-- Current number of concurrent executions

	current_queued: INTEGER
			-- Current number of queued requests

	name: STRING
			-- Bulkhead identifier for logging/debugging

	total_acquired: INTEGER_64
			-- Total successful acquisitions (statistics)

	total_rejected: INTEGER_64
			-- Total rejected requests (statistics)

feature -- Status

	is_full: BOOLEAN
			-- Is the bulkhead at capacity?
		do
			Result := current_concurrent >= max_concurrent
		end

	is_queue_full: BOOLEAN
			-- Is the queue at capacity?
		do
			Result := current_queued >= max_queue
		end

	available_permits: INTEGER
			-- Number of permits currently available
		do
			Result := max_concurrent - current_concurrent
			if Result < 0 then
				Result := 0
			end
		ensure
			non_negative: Result >= 0
		end

	queue_space: INTEGER
			-- Number of queue slots available
		do
			Result := max_queue - current_queued
			if Result < 0 then
				Result := 0
			end
		ensure
			non_negative: Result >= 0
		end

	utilization_percent: REAL_64
			-- Current utilization as percentage (0.0 to 100.0)
		do
			if max_concurrent > 0 then
				Result := (current_concurrent / max_concurrent) * 100.0
			end
		ensure
			valid_range: Result >= 0.0 and Result <= 100.0
		end

feature -- Operations

	acquire: BOOLEAN
			-- Try to acquire a permit.
			-- Returns True if acquired, False if bulkhead is full.
		do
			if current_concurrent < max_concurrent then
				current_concurrent := current_concurrent + 1
				total_acquired := total_acquired + 1
				Result := True
			else
				total_rejected := total_rejected + 1
				Result := False
			end
		ensure
			acquired_increments: Result implies current_concurrent = old current_concurrent + 1
			rejected_unchanged: not Result implies current_concurrent = old current_concurrent
		end

	try_acquire: BOOLEAN
			-- Alias for `acquire' for clarity.
		do
			Result := acquire
		end

	release
			-- Release a permit after operation completes.
		require
			has_permit: current_concurrent > 0
		do
			current_concurrent := current_concurrent - 1
		ensure
			decremented: current_concurrent = old current_concurrent - 1
		end

	release_if_held
			-- Release a permit if one is held (safe version).
		do
			if current_concurrent > 0 then
				current_concurrent := current_concurrent - 1
			end
		ensure
			decremented_or_zero: current_concurrent = (old current_concurrent - 1).max (0)
		end

feature -- Configuration

	set_name (a_name: STRING)
			-- Set bulkhead name for identification.
		require
			name_not_empty: a_name /= Void and then not a_name.is_empty
		do
			name := a_name
		ensure
			name_set: name = a_name
		end

	set_max_concurrent (a_limit: INTEGER)
			-- Change the concurrent limit.
		require
			positive: a_limit > 0
		do
			max_concurrent := a_limit
		ensure
			set: max_concurrent = a_limit
		end

	set_max_queue (a_limit: INTEGER)
			-- Change the queue limit.
		require
			non_negative: a_limit >= 0
		do
			max_queue := a_limit
		ensure
			set: max_queue = a_limit
		end

feature -- Statistics

	reset_statistics
			-- Reset acquisition/rejection counters.
		do
			total_acquired := 0
			total_rejected := 0
		ensure
			reset: total_acquired = 0 and total_rejected = 0
		end

	rejection_rate: REAL_64
			-- Rejection rate as percentage (0.0 to 100.0)
		local
			l_total: INTEGER_64
		do
			l_total := total_acquired + total_rejected
			if l_total > 0 then
				Result := (total_rejected / l_total) * 100.0
			end
		ensure
			valid_range: Result >= 0.0 and Result <= 100.0
		end

feature -- Output

	status_string: STRING
			-- Human-readable status
		do
			create Result.make (100)
			Result.append ("Bulkhead[")
			Result.append (name)
			Result.append ("]: ")
			Result.append (current_concurrent.out)
			Result.append ("/")
			Result.append (max_concurrent.out)
			Result.append (" (")
			Result.append (utilization_percent.truncated_to_integer.out)
			Result.append ("%% utilized)")
		end

invariant
	positive_max_concurrent: max_concurrent > 0
	non_negative_max_queue: max_queue >= 0
	non_negative_current: current_concurrent >= 0 and current_queued >= 0
	current_within_limit: current_concurrent <= max_concurrent + 1 -- +1 for race condition tolerance
	name_not_void: name /= Void

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
