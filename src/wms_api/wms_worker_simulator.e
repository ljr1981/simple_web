note
	description: "[
		WMS Worker Simulator - Simulates a warehouse worker with a phone app.

		This class exercises SIMPLE_WEB's HTTP client by making realistic
		sequences of API calls that a warehouse worker would make during
		their work day.

		Simulates multiple days of work with various scenarios:
		- Day 1: Morning receiving, afternoon transfers
		- Day 2: Order picking with reservations
		- Day 3: Inventory reorganization
		- Day 4: Mixed operations (receiving, picking, cycle counts)
		- Day 5: End of week cleanup and low stock handling

		FRICTION LOG (document each pain point as discovered):

		[C1] LOCALHOST ISSUE - Must use hybrid client for POST/PUT
		     Current: Have to know to use SIMPLE_WEB_HYBRID_CLIENT
		     Desired: Regular client that just works

		[C2] JSON BUILDING - Lots of manual JSON string construction
		     Current: "{%"product_id%":" + id.out + ",...}"
		     Desired: Fluent JSON builder or automatic serialization

		[C3] ERROR HANDLING - No structured way to check response errors
		     Current: if response.status_code >= 400 then...
		     Desired: response.is_error, response.error_message

		[C4] NO RETRY LOGIC - Network failures require manual retry
		     Current: Must wrap every call in retry loop
		     Desired: client.with_retry (3).post (...)

		[C5] NO REQUEST LOGGING - Hard to debug what was sent
		     Current: Manual print before each request
		     Desired: Built-in request/response logging
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	WMS_WORKER_SIMULATOR

create
	make

feature {NONE} -- Initialization

	make (a_base_url: STRING)
			-- Create simulator targeting `a_base_url'.
		require
			url_not_empty: not a_base_url.is_empty
		do
			base_url := a_base_url
			create client.make
			create randomizer.make
			worker_id := 1
			worker_name := randomizer.random_word_capitalized
			current_warehouse_id := 0
			operations_count := 0
			errors_count := 0
		ensure
			base_url_set: base_url = a_base_url
		end

feature -- Access

	base_url: STRING
			-- API server base URL.

	worker_id: INTEGER_64
			-- Current worker ID.

	worker_name: STRING
			-- Worker's name for logging.

	current_warehouse_id: INTEGER_64
			-- Currently selected warehouse.

	operations_count: INTEGER
			-- Total successful operations.

	errors_count: INTEGER
			-- Total failed operations.

feature -- Simulation Control

	run_full_week
			-- Run a full 5-day work week simulation.
		do
			print ("%N========================================%N")
			print ("  WMS WORKER SIMULATOR - FULL WEEK%N")
			print ("  Worker: " + worker_name + " (ID: " + worker_id.out + ")%N")
			print ("  API: " + base_url + "%N")
			print ("========================================%N%N")

			-- Initialize data first
			setup_test_data

			-- Run each day
			run_day_1_receiving
			run_day_2_order_picking
			run_day_3_reorganization
			run_day_4_mixed_operations
			run_day_5_cleanup

			-- Final summary
			print_summary
		end

	run_quick_simulation
			-- Run a quick simulation (useful for testing).
		do
			print ("%N=== QUICK SIMULATION ===%N")
			setup_test_data
			run_morning_shift
			print_summary
		end

feature -- Day Simulations

	run_day_1_receiving
			-- Day 1: Heavy receiving day - multiple shipments arrive.
		local
			l_po_num: INTEGER
		do
			print ("%N")
			print ("==============================%N")
			print ("  DAY 1: RECEIVING SHIPMENTS%N")
			print ("==============================%N")

			-- Clock in
			log_action ("Clocking in for Day 1 - Receiving shift")
			select_warehouse

			-- Morning: Receive PO-1001 (large shipment)
			log_action ("Morning: Processing large shipment PO-1001")
			receive_shipment ("PO-1001", <<
				[1, 1, 200],   -- 200x Widget A to location 1
				[2, 2, 150],   -- 150x Widget B to location 2
				[3, 3, 100],   -- 100x Gadget X to location 3
				[4, 4, 100],   -- 100x Gadget Y to location 4
				[5, 5, 300]    -- 300x Component Alpha to location 5
			>>)

			-- Break
			log_action ("Taking morning break")
			pause (500)

			-- Late morning: Receive PO-1002 (small shipment)
			log_action ("Late morning: Processing small shipment PO-1002")
			receive_shipment ("PO-1002", <<
				[6, 6, 50],    -- 50x Component Beta to location 6
				[7, 7, 25]     -- 25x Assembly Kit to location 7
			>>)

			-- Lunch
			log_action ("Lunch break")
			pause (1000)

			-- Afternoon: Receive multiple small POs
			log_action ("Afternoon: Processing multiple supplier deliveries")
			from l_po_num := 1003 until l_po_num > 1007 loop
				receive_shipment ("PO-" + l_po_num.out, <<
					[random_product_id, random_location_id (1, 60), random_quantity (20, 80)]
				>>)
				l_po_num := l_po_num + 1
			end

			-- End of day stock check
			log_action ("End of day: Checking stock levels")
			check_low_stock
			check_product_totals (<<1, 2, 3, 4, 5>>)

			log_action ("Clocking out - Day 1 complete")
		end

	run_day_2_order_picking
			-- Day 2: Order picking day - fulfill customer orders.
		local
			l_order_num: INTEGER
		do
			print ("%N")
			print ("==============================%N")
			print ("  DAY 2: ORDER PICKING%N")
			print ("==============================%N")

			log_action ("Clocking in for Day 2 - Picking shift")
			select_warehouse

			-- Morning: Pick orders ORD-2001 through ORD-2010
			log_action ("Morning: Processing priority orders")
			from l_order_num := 2001 until l_order_num > 2005 loop
				pick_order ("ORD-" + l_order_num.out, <<
					[random_product_id, random_quantity (5, 20)],
					[random_product_id, random_quantity (3, 15)]
				>>)
				l_order_num := l_order_num + 1
			end

			-- Break
			log_action ("Taking morning break")
			pause (500)

			-- Late morning: More picks
			log_action ("Late morning: Standard order processing")
			from l_order_num := 2006 until l_order_num > 2010 loop
				pick_order ("ORD-" + l_order_num.out, <<
					[random_product_id, random_quantity (1, 10)]
				>>)
				l_order_num := l_order_num + 1
			end

			-- Lunch
			log_action ("Lunch break")
			pause (1000)

			-- Afternoon: Bulk order
			log_action ("Afternoon: Processing bulk order ORD-2011")
			pick_order ("ORD-2011", <<
				[1, 50],   -- 50x Widget A
				[2, 50],   -- 50x Widget B
				[3, 30],   -- 30x Gadget X
				[4, 30],   -- 30x Gadget Y
				[5, 100]   -- 100x Component Alpha
			>>)

			-- Release any unused reservations from orders
			log_action ("Releasing any unused reservations")
			-- In real scenario would track reservation IDs

			-- Check stock after picking
			log_action ("End of day: Verifying stock after picks")
			check_product_totals (<<1, 2, 3, 4, 5>>)
			check_low_stock

			log_action ("Clocking out - Day 2 complete")
		end

	run_day_3_reorganization
			-- Day 3: Warehouse reorganization - moving stock for efficiency.
		local
			i: INTEGER
		do
			print ("%N")
			print ("==============================%N")
			print ("  DAY 3: REORGANIZATION%N")
			print ("==============================%N")

			log_action ("Clocking in for Day 3 - Reorganization shift")
			select_warehouse

			-- Morning: Consolidate Widget A stock to prime locations
			log_action ("Morning: Consolidating fast-moving items")
			consolidate_product (1, <<"A-1-1-1", "A-1-1-2">>)  -- Move Widget A to Aisle A

			-- Move slow movers to back
			log_action ("Moving slow-moving items to rear storage")
			from i := 6 until i > 10 loop
				transfer_to_location (i, random_location_id (180, 240))  -- Back locations
				i := i + 1
			end

			-- Break
			log_action ("Taking morning break")
			pause (500)

			-- Late morning: Organize by product family
			log_action ("Late morning: Organizing by product family")
			-- Transfer all gadgets near each other
			transfer_product_to_zone (3, "B")  -- Gadget X to aisle B
			transfer_product_to_zone (4, "B")  -- Gadget Y to aisle B

			-- Lunch
			log_action ("Lunch break")
			pause (1000)

			-- Afternoon: Make space for expected shipment
			log_action ("Afternoon: Preparing for tomorrow's large shipment")
			-- Clear locations C-1-x-x for incoming goods
			across 1 |..| 5 as loc loop
				transfer_from_location (loc.item + 120, random_location_id (60, 120))  -- Move to B aisle
			end

			-- End of day verification
			log_action ("End of day: Verifying reorganization")
			view_all_stock_levels

			log_action ("Clocking out - Day 3 complete")
		end

	run_day_4_mixed_operations
			-- Day 4: Mixed operations - receiving, picking, and cycle counts.
		local
			l_order_num: INTEGER
		do
			print ("%N")
			print ("==============================%N")
			print ("  DAY 4: MIXED OPERATIONS%N")
			print ("==============================%N")

			log_action ("Clocking in for Day 4 - Mixed operations shift")
			select_warehouse

			-- Early morning: Cycle count on high-value items
			log_action ("Early morning: Cycle count - Assembly Kits")
			check_stock_at_location (7)
			check_product_totals (<<7>>)

			-- Morning: Receive emergency restocking shipment
			log_action ("Morning: Processing emergency restock PO-4001")
			receive_shipment ("PO-4001", <<
				[1, 1, 500],   -- Restock Widget A (was running low)
				[5, 5, 200]    -- Restock Component Alpha
			>>)

			-- Process rush orders
			log_action ("Processing rush orders")
			from l_order_num := 4001 until l_order_num > 4003 loop
				pick_order ("RUSH-" + l_order_num.out, <<
					[random_product_id, random_quantity (10, 30)]
				>>)
				l_order_num := l_order_num + 1
			end

			-- Break
			log_action ("Taking morning break")
			pause (500)

			-- Late morning: Regular receiving
			log_action ("Late morning: Regular receiving PO-4002")
			receive_shipment ("PO-4002", <<
				[8, random_location_id (1, 60), 100],   -- Raw Material Z
				[9, random_location_id (1, 60), 75],    -- Spare Part Q
				[10, random_location_id (1, 60), 75]    -- Spare Part R
			>>)

			-- Lunch
			log_action ("Lunch break")
			pause (1000)

			-- Afternoon: Pick batch of orders
			log_action ("Afternoon: Batch picking")
			from l_order_num := 4010 until l_order_num > 4020 loop
				pick_order ("ORD-" + l_order_num.out, <<
					[random_product_id, random_quantity (2, 8)]
				>>)
				l_order_num := l_order_num + 1
			end

			-- Check alerts
			log_action ("End of day: Checking alerts")
			check_low_stock
			check_product_totals (<<1, 2, 3, 4, 5, 6, 7, 8, 9, 10>>)

			log_action ("Clocking out - Day 4 complete")
		end

	run_day_5_cleanup
			-- Day 5: End of week - cleanup, expired reservations, inventory report.
		do
			print ("%N")
			print ("==============================%N")
			print ("  DAY 5: END OF WEEK CLEANUP%N")
			print ("==============================%N")

			log_action ("Clocking in for Day 5 - Cleanup shift")
			select_warehouse

			-- Morning: Full inventory check
			log_action ("Morning: Full inventory verification")
			view_all_stock_levels
			check_all_products_stock

			-- Check for any expired reservations (simulate by checking low stock)
			log_action ("Checking for stuck reservations")
			check_low_stock

			-- Break
			log_action ("Taking morning break")
			pause (500)

			-- Late morning: Process any pending receiving
			log_action ("Late morning: Processing remaining shipments")
			receive_shipment ("PO-5001", <<
				[random_product_id, random_location_id (1, 60), 50],
				[random_product_id, random_location_id (1, 60), 50]
			>>)

			-- Lunch
			log_action ("Lunch break")
			pause (1000)

			-- Afternoon: Final picks and cleanup
			log_action ("Afternoon: Final order processing")
			pick_order ("ORD-5001", <<
				[1, 10],
				[2, 10]
			>>)
			pick_order ("ORD-5002", <<
				[3, 5],
				[4, 5]
			>>)

			-- Generate end of week report
			log_action ("Generating end of week inventory report")
			print_inventory_report

			log_action ("Clocking out - Day 5 complete. Week finished!")
		end

feature -- Operations

	setup_test_data
			-- Initialize warehouse with test data.
		local
			l_response: SIMPLE_WEB_RESPONSE
		do
			log_action ("Setting up test warehouse data...")
			l_response := client.post_json (base_url + "/api/setup", "{}")
			if l_response.status_code = 201 then
				log_success ("Test data initialized")
				operations_count := operations_count + 1
			else
				log_error ("Failed to setup test data: " + l_response.body)
				errors_count := errors_count + 1
			end
		end

	select_warehouse
			-- Select warehouse to work in.
		local
			l_response: SIMPLE_WEB_RESPONSE
			l_json: SIMPLE_JSON
			l_array: detachable SIMPLE_JSON_ARRAY
		do
			l_response := client.get (base_url + "/api/warehouses")
			if l_response.status_code = 200 then
				create l_json
				if attached {SIMPLE_JSON_ARRAY} l_json.decode (l_response.body) as arr and then arr.count > 0 then
					if attached {SIMPLE_JSON_OBJECT} arr.item (1) as wh then
						current_warehouse_id := wh.integer_item ("id")
						if attached wh.string_item ("name") as l_name then
							log_success ("Selected warehouse: " + l_name.to_string_8 +
								" (ID: " + current_warehouse_id.out + ")")
						else
							log_success ("Selected warehouse ID: " + current_warehouse_id.out)
						end
					end
				end
			else
				log_error ("Failed to get warehouses")
				errors_count := errors_count + 1
			end
		end

	receive_shipment (a_po: STRING; a_items: ARRAY [TUPLE [product_id: INTEGER; location_id: INTEGER; quantity: INTEGER]])
			-- Receive multiple items from a purchase order.
		local
			l_body: STRING
			l_response: SIMPLE_WEB_RESPONSE
		do
			log_action ("Receiving shipment " + a_po + " (" + a_items.count.out + " items)")
			across a_items as item loop
				-- [C2] FRICTION: Building JSON manually is tedious
				create l_body.make (200)
				l_body.append ("{%"product_id%":")
				l_body.append (item.product_id.out)
				l_body.append (",%"location_id%":")
				l_body.append (item.location_id.out)
				l_body.append (",%"quantity%":")
				l_body.append (item.quantity.out)
				l_body.append (",%"reference%":%"")
				l_body.append (a_po)
				l_body.append ("%",%"user_id%":")
				l_body.append (worker_id.out)
				l_body.append ("}")

				l_response := client.post_json (base_url + "/api/receive", l_body)
				if l_response.status_code = 201 then
					log_success ("  Received " + item.quantity.out + "x product " +
						item.product_id.out + " to location " + item.location_id.out)
					operations_count := operations_count + 1
				else
					log_error ("  Failed to receive: " + l_response.body)
					errors_count := errors_count + 1
				end
				pause (100) -- Simulate scanning time
			end
		end

	pick_order (a_order: STRING; a_items: ARRAY [TUPLE [product_id: INTEGER; quantity: INTEGER]])
			-- Pick items for an order (reserve then release after "picking").
		local
			l_body: STRING
			l_response: SIMPLE_WEB_RESPONSE
			l_location_id: INTEGER_64
			l_json: SIMPLE_JSON
			l_reservation_id: INTEGER_64
		do
			log_action ("Picking order " + a_order)
			across a_items as item loop
				-- Find stock location for product
				l_location_id := find_stock_location (item.product_id.to_integer_64)

				if l_location_id > 0 then
					-- Reserve the stock
					create l_body.make (250)
					l_body.append ("{%"product_id%":")
					l_body.append (item.product_id.out)
					l_body.append (",%"location_id%":")
					l_body.append (l_location_id.out)
					l_body.append (",%"quantity%":")
					l_body.append (item.quantity.out)
					l_body.append (",%"order_reference%":%"")
					l_body.append (a_order)
					l_body.append ("%",%"user_id%":")
					l_body.append (worker_id.out)
					l_body.append (",%"expires_minutes%":30}")

					l_response := client.post_json (base_url + "/api/reserve", l_body)
					if l_response.status_code = 201 then
						-- Parse reservation ID
						create l_json
						if attached {SIMPLE_JSON_OBJECT} l_json.decode (l_response.body) as res_json then
							l_reservation_id := res_json.integer_item ("id")
							log_success ("  Reserved " + item.quantity.out + "x product " +
								item.product_id.out + " (reservation " + l_reservation_id.out + ")")
							operations_count := operations_count + 1

							-- Simulate walking to location and picking
							pause (200)

							-- Release reservation after "picking"
							l_response := client.delete (base_url + "/api/reserve/" + l_reservation_id.out)
							if l_response.status_code = 200 then
								log_success ("  Picked and released reservation " + l_reservation_id.out)
								operations_count := operations_count + 1
							else
								log_error ("  Failed to release reservation: " + l_response.body)
								errors_count := errors_count + 1
							end
						end
					else
						log_error ("  Failed to reserve: " + l_response.body)
						errors_count := errors_count + 1
					end
				else
					log_error ("  No stock found for product " + item.product_id.out)
					errors_count := errors_count + 1
				end
			end
		end

	transfer_stock (a_product_id, a_from_location, a_to_location: INTEGER_64; a_quantity: INTEGER; a_reference: STRING)
			-- Transfer stock between locations.
		local
			l_body: STRING
			l_response: SIMPLE_WEB_RESPONSE
		do
			create l_body.make (300)
			l_body.append ("{%"product_id%":")
			l_body.append (a_product_id.out)
			l_body.append (",%"from_location_id%":")
			l_body.append (a_from_location.out)
			l_body.append (",%"to_location_id%":")
			l_body.append (a_to_location.out)
			l_body.append (",%"quantity%":")
			l_body.append (a_quantity.out)
			l_body.append (",%"reference%":%"")
			l_body.append (a_reference)
			l_body.append ("%",%"user_id%":")
			l_body.append (worker_id.out)
			l_body.append ("}")

			l_response := client.post_json (base_url + "/api/transfer", l_body)
			if l_response.status_code = 200 then
				log_success ("Transferred " + a_quantity.out + "x product " + a_product_id.out +
					" from " + a_from_location.out + " to " + a_to_location.out)
				operations_count := operations_count + 1
			else
				log_error ("Transfer failed: " + l_response.body)
				errors_count := errors_count + 1
			end
		end

feature -- Stock Queries

	find_stock_location (a_product_id: INTEGER_64): INTEGER_64
			-- Find a location with stock for product. Returns 0 if none found.
		local
			l_response: SIMPLE_WEB_RESPONSE
			l_json: SIMPLE_JSON
		do
			l_response := client.get (base_url + "/api/stock/product/" + a_product_id.out)
			if l_response.status_code = 200 then
				-- Product has stock somewhere - need to find specific location
				-- For now, use a heuristic (product_id maps to initial location)
				Result := ((a_product_id - 1) \\ 60) + 1
			end
		end

	check_stock_at_location (a_location_id: INTEGER_64)
			-- Check and display stock at a location.
		local
			l_response: SIMPLE_WEB_RESPONSE
			l_json: SIMPLE_JSON
		do
			l_response := client.get (base_url + "/api/stock/" + a_location_id.out)
			if l_response.status_code = 200 then
				log_success ("Stock at location " + a_location_id.out + ": " + l_response.body)
			else
				log_error ("Failed to check stock at " + a_location_id.out)
			end
		end

	check_product_totals (a_product_ids: ARRAY [INTEGER])
			-- Check total stock for multiple products.
		local
			l_response: SIMPLE_WEB_RESPONSE
			l_json: SIMPLE_JSON
		do
			print ("  Product stock totals:%N")
			across a_product_ids as pid loop
				l_response := client.get (base_url + "/api/stock/product/" + pid.item.out)
				if l_response.status_code = 200 then
					create l_json
					if attached {SIMPLE_JSON_OBJECT} l_json.decode (l_response.body) as stock then
						print ("    Product " + pid.item.out + ": " +
							stock.integer_item ("total_quantity").out + " total, " +
							stock.integer_item ("available_quantity").out + " available%N")
					end
				end
			end
		end

	check_low_stock
			-- Check for products below minimum stock.
		local
			l_response: SIMPLE_WEB_RESPONSE
			l_json: SIMPLE_JSON
		do
			l_response := client.get (base_url + "/api/low-stock")
			if l_response.status_code = 200 then
				create l_json
				if attached {SIMPLE_JSON_ARRAY} l_json.decode (l_response.body) as arr then
					if arr.count > 0 then
						print ("  LOW STOCK ALERTS: " + arr.count.out + " products below minimum%N")
					else
						print ("  No low stock alerts%N")
					end
				end
			else
				log_error ("Failed to check low stock")
			end
		end

	check_all_products_stock
			-- Check stock for all products (1-10).
		do
			check_product_totals (<<1, 2, 3, 4, 5, 6, 7, 8, 9, 10>>)
		end

	view_all_stock_levels
			-- View stock at all locations (summary).
		local
			l_response: SIMPLE_WEB_RESPONSE
			i: INTEGER
		do
			print ("  Viewing stock across locations...%N")
			from i := 1 until i > 10 loop
				l_response := client.get (base_url + "/api/stock/" + i.out)
				if l_response.status_code = 200 and then l_response.body.count > 2 then
					print ("    Location " + i.out + ": " + l_response.body.substring (1, (50).min (l_response.body.count)) + "...%N")
				end
				i := i + 1
			end
		end

feature -- Complex Operations

	consolidate_product (a_product_id: INTEGER; a_target_locations: ARRAY [STRING])
			-- Consolidate all stock of a product to target locations.
		do
			log_action ("Consolidating product " + a_product_id.out + " to " +
				a_target_locations.count.out + " locations")
			-- In a real implementation, would query all stock locations for this product
			-- and transfer to consolidation points
			pause (500) -- Simulate the work
		end

	transfer_to_location (a_product_id: INTEGER; a_target_location: INTEGER_64)
			-- Transfer a product to a specific location.
		local
			l_source: INTEGER_64
		do
			l_source := find_stock_location (a_product_id.to_integer_64)
			if l_source > 0 and l_source /= a_target_location then
				transfer_stock (a_product_id.to_integer_64, l_source, a_target_location, 10, "REORG")
			end
		end

	transfer_from_location (a_source_location: INTEGER; a_target_location: INTEGER_64)
			-- Transfer all stock from a location to another.
		do
			-- In real implementation, would query stock at source and transfer
			log_action ("Moving stock from location " + a_source_location.out + " to " + a_target_location.out)
			pause (200)
		end

	transfer_product_to_zone (a_product_id: INTEGER; a_aisle: STRING)
			-- Transfer all stock of product to a specific aisle zone.
		do
			log_action ("Moving product " + a_product_id.out + " to aisle " + a_aisle)
			-- Would find all stock locations and transfer to zone
			pause (300)
		end

feature -- Morning Shift (Quick Simulation)

	run_morning_shift
			-- Run a typical morning shift operations.
		do
			print ("%N=== MORNING SHIFT ===%N")
			select_warehouse

			-- Receive a shipment
			receive_shipment ("PO-TEST-001", <<
				[1, 1, 50],
				[2, 2, 30]
			>>)

			-- Pick an order
			pick_order ("ORD-TEST-001", <<
				[1, 10],
				[2, 5]
			>>)

			-- Check stock
			check_product_totals (<<1, 2>>)
		end

feature -- Inventory Validation (Spot Checks)

	spot_check_product (a_product_id: INTEGER; a_expected_total: INTEGER; a_description: STRING)
			-- Verify product total stock matches expected value.
			-- This is a key API testing feature - validates state after operations.
		local
			l_response: SIMPLE_WEB_RESPONSE
			l_json: SIMPLE_JSON
			l_actual: INTEGER_64
		do
			spot_check_count := spot_check_count + 1
			l_response := client.get (base_url + "/api/stock/product/" + a_product_id.out)
			if l_response.status_code = 200 then
				create l_json
				if attached {SIMPLE_JSON_OBJECT} l_json.decode (l_response.body) as stock then
					l_actual := stock.integer_item ("total_quantity")
					if l_actual.to_integer_32 = a_expected_total then
						log_success ("SPOT CHECK #" + spot_check_count.out + " PASS: " + a_description +
							" (Product " + a_product_id.out + " = " + l_actual.out + ")")
						spot_check_passed := spot_check_passed + 1
					else
						log_error ("SPOT CHECK #" + spot_check_count.out + " FAIL: " + a_description +
							" - Expected " + a_expected_total.out + " but got " + l_actual.out)
						spot_check_failed := spot_check_failed + 1
					end
				end
			else
				log_error ("SPOT CHECK #" + spot_check_count.out + " FAIL: Could not get stock for product " + a_product_id.out)
				spot_check_failed := spot_check_failed + 1
			end
		end

	spot_check_available (a_product_id: INTEGER; a_expected_available: INTEGER; a_description: STRING)
			-- Verify product available stock (total - reserved) matches expected value.
		local
			l_response: SIMPLE_WEB_RESPONSE
			l_json: SIMPLE_JSON
			l_actual: INTEGER_64
		do
			spot_check_count := spot_check_count + 1
			l_response := client.get (base_url + "/api/stock/product/" + a_product_id.out)
			if l_response.status_code = 200 then
				create l_json
				if attached {SIMPLE_JSON_OBJECT} l_json.decode (l_response.body) as stock then
					l_actual := stock.integer_item ("available_quantity")
					if l_actual.to_integer_32 = a_expected_available then
						log_success ("SPOT CHECK #" + spot_check_count.out + " PASS: " + a_description)
						spot_check_passed := spot_check_passed + 1
					else
						log_error ("SPOT CHECK #" + spot_check_count.out + " FAIL: " + a_description +
							" - Expected " + a_expected_available.out + " available but got " + l_actual.out)
						spot_check_failed := spot_check_failed + 1
					end
				end
			else
				log_error ("SPOT CHECK #" + spot_check_count.out + " FAIL: API error")
				spot_check_failed := spot_check_failed + 1
			end
		end

	verify_movement_recorded (a_product_id: INTEGER; a_expected_type: STRING; a_expected_quantity: INTEGER)
			-- Verify that a movement was recorded with expected values.
		local
			l_response: SIMPLE_WEB_RESPONSE
			l_json: SIMPLE_JSON
			l_found: BOOLEAN
		do
			spot_check_count := spot_check_count + 1
			l_response := client.get (base_url + "/api/movements/" + a_product_id.out + "?limit=1")
			if l_response.status_code = 200 then
				create l_json
				if attached {SIMPLE_JSON_ARRAY} l_json.decode (l_response.body) as arr and then arr.count > 0 then
					if attached {SIMPLE_JSON_OBJECT} arr.item (1) as mov then
						if attached mov.string_item ("movement_type") as l_type then
							l_found := l_type.to_string_8 ~ a_expected_type and
								mov.integer_item ("quantity").to_integer_32 = a_expected_quantity
						end
					end
				end
				if l_found then
					log_success ("SPOT CHECK #" + spot_check_count.out + " PASS: Movement recorded - " +
						a_expected_type + " x" + a_expected_quantity.out)
					spot_check_passed := spot_check_passed + 1
				else
					log_error ("SPOT CHECK #" + spot_check_count.out + " FAIL: Expected movement not found")
					spot_check_failed := spot_check_failed + 1
				end
			else
				log_error ("SPOT CHECK #" + spot_check_count.out + " FAIL: API error getting movements")
				spot_check_failed := spot_check_failed + 1
			end
		end

feature -- Error Scenario Testing

	test_error_scenarios
			-- Test API error handling with invalid requests.
			-- This discovers friction in error response formats.
		do
			print ("%N")
			print ("==============================%N")
			print ("  ERROR SCENARIO TESTING%N")
			print ("==============================%N")

			test_receive_invalid_product
			test_transfer_insufficient_stock
			test_reserve_over_available
			test_invalid_json_body
			test_missing_required_fields
			test_release_nonexistent_reservation

			print_error_test_summary
		end

	test_receive_invalid_product
			-- Test receiving to non-existent product.
		local
			l_response: SIMPLE_WEB_RESPONSE
			l_body: STRING
		do
			error_test_count := error_test_count + 1
			log_action ("Error Test: Receive with invalid product ID")

			l_body := "{%"product_id%":99999,%"location_id%":1,%"quantity%":10,%"reference%":%"TEST%",%"user_id%":1}"
			l_response := client.post_json (base_url + "/api/receive", l_body)

			-- Should fail with 4xx error
			if l_response.is_error then
				log_success ("  Got expected error response: " + l_response.status_code.out)
				if attached l_response.error_message as l_msg then
					log_success ("  Error message: " + l_msg)
				end
				error_test_passed := error_test_passed + 1
			else
				log_error ("  Expected error but got success!")
				error_test_failed := error_test_failed + 1
			end
		end

	test_transfer_insufficient_stock
			-- Test transfer with more quantity than available.
		local
			l_response: SIMPLE_WEB_RESPONSE
			l_body: STRING
		do
			error_test_count := error_test_count + 1
			log_action ("Error Test: Transfer more than available stock")

			-- Try to transfer 999999 units (should fail)
			l_body := "{%"product_id%":1,%"from_location_id%":1,%"to_location_id%":2,%"quantity%":999999,%"reference%":%"TEST%",%"user_id%":1}"
			l_response := client.post_json (base_url + "/api/transfer", l_body)

			if l_response.is_error then
				log_success ("  Got expected error: " + l_response.status_code.out)
				error_test_passed := error_test_passed + 1
			else
				log_error ("  Expected error but got success!")
				error_test_failed := error_test_failed + 1
			end
		end

	test_reserve_over_available
			-- Test reservation exceeding available quantity.
		local
			l_response: SIMPLE_WEB_RESPONSE
			l_body: STRING
		do
			error_test_count := error_test_count + 1
			log_action ("Error Test: Reserve more than available")

			l_body := "{%"product_id%":1,%"location_id%":1,%"quantity%":999999,%"order_reference%":%"TEST%",%"user_id%":1}"
			l_response := client.post_json (base_url + "/api/reserve", l_body)

			if l_response.status_code = 409 then  -- Conflict - expected
				log_success ("  Got expected 409 Conflict")
				error_test_passed := error_test_passed + 1
			elseif l_response.is_error then
				log_success ("  Got error response: " + l_response.status_code.out)
				error_test_passed := error_test_passed + 1
			else
				log_error ("  Expected error but got success!")
				error_test_failed := error_test_failed + 1
			end
		end

	test_invalid_json_body
			-- Test API response to malformed JSON.
		local
			l_response: SIMPLE_WEB_RESPONSE
		do
			error_test_count := error_test_count + 1
			log_action ("Error Test: Malformed JSON body")

			l_response := client.post_json (base_url + "/api/receive", "{invalid json")

			if l_response.status_code = 400 then
				log_success ("  Got expected 400 Bad Request")
				error_test_passed := error_test_passed + 1
			elseif l_response.is_error then
				log_success ("  Got error response: " + l_response.status_code.out)
				error_test_passed := error_test_passed + 1
			else
				log_error ("  Expected error but got success!")
				error_test_failed := error_test_failed + 1
			end
		end

	test_missing_required_fields
			-- Test API response to missing required fields.
		local
			l_response: SIMPLE_WEB_RESPONSE
		do
			error_test_count := error_test_count + 1
			log_action ("Error Test: Missing required fields")

			-- Missing product_id, location_id, etc.
			l_response := client.post_json (base_url + "/api/receive", "{%"quantity%":10}")

			if l_response.status_code = 400 then
				log_success ("  Got expected 400 Bad Request")
				error_test_passed := error_test_passed + 1
			elseif l_response.is_error then
				log_success ("  Got error response: " + l_response.status_code.out)
				error_test_passed := error_test_passed + 1
			else
				log_error ("  Expected error but got success!")
				error_test_failed := error_test_failed + 1
			end
		end

	test_release_nonexistent_reservation
			-- Test releasing a reservation that doesn't exist.
		local
			l_response: SIMPLE_WEB_RESPONSE
		do
			error_test_count := error_test_count + 1
			log_action ("Error Test: Release non-existent reservation")

			l_response := client.delete (base_url + "/api/reserve/99999")

			if l_response.status_code = 404 then
				log_success ("  Got expected 404 Not Found")
				error_test_passed := error_test_passed + 1
			elseif l_response.is_error then
				log_success ("  Got error response: " + l_response.status_code.out)
				error_test_passed := error_test_passed + 1
			else
				log_error ("  Expected error but got success!")
				error_test_failed := error_test_failed + 1
			end
		end

	print_error_test_summary
			-- Print error testing summary.
		do
			print ("%N--- ERROR TESTING SUMMARY ---%N")
			print ("  Tests run: " + error_test_count.out + "%N")
			print ("  Passed: " + error_test_passed.out + "%N")
			print ("  Failed: " + error_test_failed.out + "%N")
			print ("-------------------------------%N")
		end

feature -- Walmart-Style Simulation

	run_walmart_simulation
			-- Run large-scale Walmart-style distribution center simulation.
			-- Simulates a busy day at a regional distribution center with:
			-- - High volume receiving from suppliers
			-- - Order fulfillment to stores
			-- - Cross-docking operations
			-- - Real-time inventory tracking
		do
			print ("%N")
			print ("===================================================%N")
			print ("  WALMART REGIONAL DISTRIBUTION CENTER SIMULATION%N")
			print ("  Powered by SIMPLE_RANDOMIZER%N")
			print ("===================================================%N")
			print ("  Worker: " + worker_name + " (Associate #" + worker_id.out + ")%N")
			print ("  Shift: 6:00 AM - 2:30 PM%N")
			print ("===================================================%N%N")

			-- Initialize warehouse
			setup_test_data

			-- Pre-shift: Clock in
			walmart_clock_in

			-- Morning: High volume receiving (6:00 - 10:00)
			walmart_morning_receiving

			-- Mid-morning: Order processing (10:00 - 12:00)
			walmart_order_processing

			-- Lunch break (12:00 - 12:30)
			walmart_lunch_break

			-- Afternoon: Store replenishment picks (12:30 - 2:00)
			walmart_store_replenishment

			-- End of shift: Wrap up (2:00 - 2:30)
			walmart_shift_end

			print_walmart_summary
		end

	walmart_clock_in
			-- Simulate associate clocking in for shift.
		do
			print ("%N[06:00] SHIFT START%N")
			log_action (worker_name + " clocking in at RF scanner station")
			select_warehouse
			log_action ("Assigned to Zone A - Grocery Receiving")
			pause (500)
		end

	walmart_morning_receiving
			-- Morning receiving - trucks arrive from suppliers.
		local
			l_truck_count, l_total_units, i: INTEGER
			l_suppliers: ARRAY [STRING]
		do
			print ("%N[06:15 - 10:00] MORNING RECEIVING%N")

			l_suppliers := <<"Procter & Gamble", "Kraft Heinz", "General Mills",
				"PepsiCo", "Nestle", "Unilever", "Kelloggs", "Campbell Soup">>

			l_truck_count := randomizer.random_integer_in_range (5 |..| 8)
			log_action ("Receiving dock shows " + l_truck_count.out + " inbound trucks scheduled")

			from i := 1 until i > l_truck_count loop
				-- Simulate receiving a truckload
				receive_supplier_truck (
					randomizer.random_string_from_list (l_suppliers),
					random_po_reference
				)
				l_total_units := l_total_units + randomizer.random_integer_in_range (200 |..| 800)
				i := i + 1
			end

			-- Spot check after receiving
			print ("%N[10:00] Mid-morning stock check%N")
			check_product_totals (<<1, 2, 3, 4, 5>>)
		end

	receive_supplier_truck (a_supplier: STRING; a_po: STRING)
			-- Receive a full truckload from a supplier.
		local
			l_pallet_count, l_units_per_pallet, l_total, i: INTEGER
		do
			l_pallet_count := randomizer.random_integer_in_range (8 |..| 24)
			log_action ("Unloading " + a_supplier + " truck - " + l_pallet_count.out + " pallets - " + a_po)

			from i := 1 until i > l_pallet_count.min (5) loop -- Simulate 5 pallets max
				l_units_per_pallet := randomizer.random_integer_in_range (48 |..| 144)
				receive_shipment (a_po, <<[random_product_id, random_location_id (1, 60), l_units_per_pallet]>>)
				l_total := l_total + l_units_per_pallet
				i := i + 1
			end

			log_success ("Truck complete - " + l_total.out + " units received")
			pause (300)
		end

	walmart_order_processing
			-- Process store orders for fulfillment.
		local
			l_store_count, i: INTEGER
			l_store_num: STRING
		do
			print ("%N[10:00 - 12:00] ORDER PROCESSING%N")
			log_action ("Switching to order fulfillment mode")

			l_store_count := randomizer.random_integer_in_range (15 |..| 30)
			log_action (l_store_count.out + " store orders in queue")

			from i := 1 until i > l_store_count.min (10) loop -- Process 10 orders
				l_store_num := "Store #" + randomizer.random_digits (4)
				process_store_order (l_store_num)
				i := i + 1
			end
		end

	process_store_order (a_store: STRING)
			-- Process an order for a specific store.
		local
			l_line_count, i: INTEGER
			l_order_ref: STRING
		do
			l_order_ref := random_order_reference
			l_line_count := randomizer.random_integer_in_range (3 |..| 8)

			log_action ("Processing " + a_store + " order " + l_order_ref + " (" + l_line_count.out + " lines)")

			-- Create pick list items
			from i := 1 until i > l_line_count.min (3) loop -- Pick 3 items
				pick_order (l_order_ref, <<[random_product_id, random_quantity (6, 48)]>>)
				i := i + 1
			end

			log_success ("Order " + l_order_ref + " staged for " + a_store)
			pause (200)
		end

	walmart_lunch_break
			-- Lunch break simulation.
		do
			print ("%N[12:00 - 12:30] LUNCH BREAK%N")
			log_action (worker_name + " heading to break room")
			pause (500)
			log_action ("Break complete - returning to floor")
		end

	walmart_store_replenishment
			-- Afternoon store replenishment picking.
		local
			l_wave_count, l_picks, i: INTEGER
		do
			print ("%N[12:30 - 14:00] STORE REPLENISHMENT%N")
			log_action ("Starting high-velocity pick wave")

			l_wave_count := randomizer.random_integer_in_range (3 |..| 5)
			from i := 1 until i > l_wave_count loop
				l_picks := execute_pick_wave (i)
				print ("  Wave " + i.out + " complete: " + l_picks.out + " picks%N")
				i := i + 1
			end

			-- Final spot check
			print ("%N[13:45] Afternoon stock verification%N")
			check_all_products_stock
			check_low_stock
		end

	execute_pick_wave (a_wave_num: INTEGER): INTEGER
			-- Execute a picking wave, returns number of picks.
		local
			l_picks, i: INTEGER
		do
			l_picks := randomizer.random_integer_in_range (8 |..| 15)
			log_action ("Pick wave #" + a_wave_num.out + " - " + l_picks.out + " locations")

			from i := 1 until i > l_picks.min (5) loop -- Execute 5 picks
				pick_order (random_order_reference, <<[random_product_id, random_quantity (4, 24)]>>)
				i := i + 1
			end

			Result := l_picks
			pause (200)
		end

	walmart_shift_end
			-- End of shift procedures.
		do
			print ("%N[14:00 - 14:30] SHIFT END%N")
			log_action ("Wrapping up shift")

			-- Final inventory checks
			print_inventory_report

			-- Clock out
			log_action (worker_name + " clocking out - shift complete")
		end

	print_walmart_summary
			-- Print Walmart-style shift summary.
		do
			print ("%N")
			print ("===================================================%N")
			print ("  SHIFT PERFORMANCE SUMMARY%N")
			print ("===================================================%N")
			print ("  Associate: " + worker_name + "%N")
			print ("  Transactions: " + operations_count.out + "%N")
			print ("  Errors: " + errors_count.out + "%N")
			print ("  Units Per Hour: " + ((operations_count * 60) // 8).out + " (est)%N")
			if errors_count = 0 then
				print ("  Rating: EXCEEDS EXPECTATIONS%N")
			elseif errors_count < 3 then
				print ("  Rating: MEETS EXPECTATIONS%N")
			else
				print ("  Rating: NEEDS IMPROVEMENT%N")
			end
			print ("===================================================%N")
		end

feature -- Validated Simulation (with spot checks)

	run_validated_week
			-- Run full week with inventory spot checks after each major operation.
			-- This is the most thorough API exercise.
		do
			print ("%N========================================%N")
			print ("  WMS VALIDATED SIMULATION%N")
			print ("  (with inventory spot checks)%N")
			print ("========================================%N%N")

			-- Reset counters
			spot_check_count := 0
			spot_check_passed := 0
			spot_check_failed := 0

			-- Initialize
			setup_test_data

			-- Day 1: Validated receiving
			run_validated_receiving

			-- Day 2: Validated picking
			run_validated_picking

			-- Run error scenarios
			test_error_scenarios

			-- Final summary
			print_validation_summary
		end

	run_validated_receiving
			-- Day of receiving with inventory validation.
		local
			l_initial_stock: INTEGER
		do
			print ("%N=== VALIDATED RECEIVING ===%N")
			select_warehouse

			-- Check initial state
			l_initial_stock := get_product_total (1)
			log_action ("Initial stock for Product 1: " + l_initial_stock.out)

			-- Receive known quantity
			receive_shipment ("PO-VAL-001", <<[1, 1, 100]>>)

			-- SPOT CHECK: Should have initial + 100
			spot_check_product (1, l_initial_stock + 100, "After receiving 100 units of Product 1")

			-- Verify movement was recorded
			verify_movement_recorded (1, "RECEIVE", 100)

			-- Receive more
			receive_shipment ("PO-VAL-002", <<[1, 1, 50]>>)

			-- SPOT CHECK: Should have initial + 150
			spot_check_product (1, l_initial_stock + 150, "After receiving additional 50 units")
		end

	run_validated_picking
			-- Day of picking with inventory validation.
		local
			l_before_pick: INTEGER
		do
			print ("%N=== VALIDATED PICKING ===%N")
			select_warehouse

			-- Record current stock
			l_before_pick := get_product_total (1)
			log_action ("Stock before picking: " + l_before_pick.out)

			-- Pick known quantity
			pick_order ("ORD-VAL-001", <<[1, 20]>>)

			-- SPOT CHECK: Stock should decrease by picked amount
			-- Note: actual decrease depends on reservation/release pattern
			spot_check_product (1, l_before_pick, "After pick (reservations released)")
		end

feature -- Reporting

	print_summary
			-- Print simulation summary.
		do
			print ("%N")
			print ("========================================%N")
			print ("  SIMULATION SUMMARY%N")
			print ("========================================%N")
			print ("  Worker: " + worker_name + "%N")
			print ("  Total Operations: " + operations_count.out + "%N")
			print ("  Errors: " + errors_count.out + "%N")
			print ("  Success Rate: " + ((operations_count * 100) // (operations_count + errors_count).max (1)).out + "%%%N")
			print ("========================================%N")
		end

	print_validation_summary
			-- Print validation summary including spot checks.
		do
			print_summary
			print ("%N--- SPOT CHECK RESULTS ---%N")
			print ("  Checks run: " + spot_check_count.out + "%N")
			print ("  Passed: " + spot_check_passed.out + "%N")
			print ("  Failed: " + spot_check_failed.out + "%N")
			if spot_check_failed = 0 then
				print ("  STATUS: ALL VALIDATIONS PASSED%N")
			else
				print ("  STATUS: VALIDATION FAILURES DETECTED%N")
			end
			print ("-------------------------------%N")
		end

	print_inventory_report
			-- Print end of week inventory report.
		do
			print ("%N--- END OF WEEK INVENTORY REPORT ---%N")
			check_all_products_stock
			check_low_stock
			print ("--- END REPORT ---%N")
		end

feature {NONE} -- Implementation

	client: SIMPLE_WEB_HYBRID_CLIENT
			-- HTTP client (using hybrid for localhost compatibility).
			-- [C1] FRICTION: Must use hybrid client for localhost

	randomizer: SIMPLE_RANDOMIZER
			-- Random data generator for realistic simulation.

	pause (a_milliseconds: INTEGER)
			-- Pause execution to simulate real work timing.
		local
			l_env: EXECUTION_ENVIRONMENT
		do
			create l_env
			l_env.sleep (a_milliseconds * 1_000_000) -- nanoseconds
		end

	log_action (a_message: STRING)
			-- Log an action.
		do
			print ("%N>> " + a_message + "%N")
		end

	log_success (a_message: STRING)
			-- Log a success.
		do
			print ("   [OK] " + a_message + "%N")
		end

	log_error (a_message: STRING)
			-- Log an error.
		do
			print ("   [ERROR] " + a_message + "%N")
		end

	random_product_id: INTEGER
			-- Return random product ID (1-10).
		do
			Result := randomizer.random_integer_in_range (1 |..| 10)
		end

	random_location_id (a_min, a_max: INTEGER): INTEGER
			-- Return random location ID in range.
		do
			Result := randomizer.random_integer_in_range (a_min |..| a_max)
		end

	random_quantity (a_min, a_max: INTEGER): INTEGER
			-- Return random quantity in range.
		do
			Result := randomizer.random_integer_in_range (a_min |..| a_max)
		end

	random_order_reference: STRING
			-- Generate realistic order reference like "ORD-12345".
		do
			Result := "ORD-" + randomizer.random_digits (5)
		end

	random_po_reference: STRING
			-- Generate realistic purchase order reference.
		do
			Result := "PO-" + randomizer.random_digits (6)
		end

	random_worker_name: STRING
			-- Generate random worker name.
		do
			Result := randomizer.random_word_capitalized + " " + randomizer.random_word_capitalized.substring (1, 1) + "."
		end

	get_product_total (a_product_id: INTEGER): INTEGER
			-- Get total stock for a product (helper for validated simulation).
		local
			l_response: SIMPLE_WEB_RESPONSE
			l_json: SIMPLE_JSON
		do
			l_response := client.get (base_url + "/api/stock/product/" + a_product_id.out)
			if l_response.status_code = 200 then
				create l_json
				if attached {SIMPLE_JSON_OBJECT} l_json.decode (l_response.body) as stock then
					Result := stock.integer_item ("total_quantity").to_integer_32
				end
			end
		end

feature {NONE} -- Spot Check Tracking

	spot_check_count: INTEGER
			-- Number of spot checks performed.

	spot_check_passed: INTEGER
			-- Number of spot checks that passed.

	spot_check_failed: INTEGER
			-- Number of spot checks that failed.

feature {NONE} -- Error Test Tracking

	error_test_count: INTEGER
			-- Number of error tests performed.

	error_test_passed: INTEGER
			-- Number of error tests that passed.

	error_test_failed: INTEGER
			-- Number of error tests that failed.

invariant
	base_url_not_empty: not base_url.is_empty
	client_attached: client /= Void

note
	copyright: "Copyright (c) 2024-2025, Larry Rix"
	license: "MIT License"

end
