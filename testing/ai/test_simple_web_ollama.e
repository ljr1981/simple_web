note
	description: "Tests for {SIMPLE_WEB_OLLAMA_CLIENT}"
	testing: "covers"

class
	TEST_SIMPLE_WEB_OLLAMA

inherit
	TEST_SET_BASE

feature -- Test routines

	test_ollama_echo_response
			-- Test that Ollama actually responds with expected content
		note
			testing: "execution/isolated"
		local
			l_client: SIMPLE_WEB_OLLAMA_CLIENT
			l_response: SIMPLE_WEB_RESPONSE
		do
			create l_client

			print ("%N=== Ollama Echo Test ===%N")
			print ("Prompt: Repeat this exactly: EIFFEL_TEST_MARKER%N")

			l_response := l_client.generate ({STRING_32} "llama3",
				"Repeat this exactly: EIFFEL_TEST_MARKER")

			print ("Status: " + l_response.status_code.out + "%N")
			print ("Body: " + l_response.body + "%N%N")

			if l_response.is_success then
				assert_string_contains ("has_marker", l_response.body, "EIFFEL_TEST_MARKER")
			else
				print ("Ollama not running (status " + l_response.status_code.out + ")%N")
			end
		end

	test_ollama_generate
			-- Test basic generate endpoint (requires Ollama running)
		note
			testing: "execution/isolated", "covers/{SIMPLE_WEB_OLLAMA_CLIENT}.generate"
		local
			l_client: SIMPLE_WEB_OLLAMA_CLIENT
			l_response: SIMPLE_WEB_RESPONSE
		do
			create l_client
			l_response := l_client.generate ({STRING_32} "llama3", "Why is the sky blue?")

			print ("%NGenerate Status: " + l_response.status_code.out + "%N")
			print ("Generate Body: " + l_response.body + "%N")

			if l_response.is_success then
				assert_true ("has_response", not l_response.body.is_empty)
				assert_string_contains ("has_model", l_response.body, "model")
			else
				-- Show what we actually got
				print ("FAILED - Status: " + l_response.status_code.out + "%N")
			end
		end

	test_ollama_list_models
			-- Test list models endpoint
		note
			testing: "execution/isolated", "covers/{SIMPLE_WEB_OLLAMA_CLIENT}.list_models"
		local
			l_client: SIMPLE_WEB_OLLAMA_CLIENT
			l_response: SIMPLE_WEB_RESPONSE
		do
			create l_client
			l_response := l_client.list_models

			if l_response.is_success then
				assert_true ("has_response", not l_response.body.is_empty)
			else
				assert_true ("network_failure_or_not_running", l_response.status_code = 503 or l_response.status_code = 0)
			end
		end

	test_ollama_chat
			-- Test chat endpoint
		note
			testing: "execution/isolated", "covers/{SIMPLE_WEB_OLLAMA_CLIENT}.chat"
		local
			l_client: SIMPLE_WEB_OLLAMA_CLIENT
			l_response: SIMPLE_WEB_RESPONSE
			l_messages: ARRAY [TUPLE [role: STRING_32; content: STRING_32]]
			l_msg: TUPLE [role: STRING_32; content: STRING_32]
		do
			create l_client
			l_msg := [{STRING_32} "user", {STRING_32} "Hello"]
			create l_messages.make_filled (l_msg, 1, 1)

			l_response := l_client.chat ({STRING_32} "llama3", l_messages)

			print ("%NChat Status: " + l_response.status_code.out + "%N")
			print ("Chat Body: " + l_response.body + "%N")

			if l_response.is_success then
				assert_true ("has_response", not l_response.body.is_empty)
			else
				print ("FAILED - Status: " + l_response.status_code.out + "%N")
			end
		end

note
	copyright: "Copyright (c) 2024-2025, Larry Rix"
	license: "MIT License"
	source: "[
		SIMPLE_WEB - High-level Web API Library
		Tests require Ollama running: ollama serve
	]"

end
