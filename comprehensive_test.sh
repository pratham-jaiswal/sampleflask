#!/bin/bash

# Comprehensive Test Script for Flask Book + LangChain API
# Make sure the Flask app is running on http://127.0.0.1:5000

BASE_URL="http://127.0.0.1:5000"
RESULTS_FILE="test_results_shell.txt"

# Clear previous results
> "$RESULTS_FILE"

write_test_result() {
    local test_name="$1"
    local command="$2"
    local response="$3"
    local status="${4:-PASS}"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    {
        echo "================================================================================="
        echo "TEST: $test_name"
        echo "TIMESTAMP: $timestamp"
        echo "STATUS: $status"
        echo "COMMAND: $command"
        echo "RESPONSE:"
        echo "$response"
        echo ""
    } >> "$RESULTS_FILE"

    echo "================================================================================="
    echo "TEST: $test_name - $status"
    echo "TIMESTAMP: $timestamp"
    echo "COMMAND: $command"
    echo "RESPONSE: $response"
    echo ""
}

echo "================================="
echo "Comprehensive Flask API Testing (Shell)"
echo "================================="
echo ""

# Test 1: Home endpoint
echo "Testing Home Endpoint..."
command="curl -s -X GET $BASE_URL/"
response=$(curl -s -X GET "$BASE_URL/")
write_test_result "GET / (Home)" "$command" "$response"

# Test 2: Get all books (initial state)
echo "Testing Books CRUD..."
command="curl -s -X GET $BASE_URL/books"
response=$(curl -s -X GET "$BASE_URL/books")
write_test_result "GET /books (Initial state)" "$command" "$response"

# Test 3: Add test book
command="curl -s -X POST $BASE_URL/books -H 'Content-Type: application/json' -d '{\"title\": \"Shell Test Book\", \"author\": \"Shell Author\", \"year\": 2024}'"
response=$(curl -s -X POST "$BASE_URL/books" -H "Content-Type: application/json" -d '{"title": "Shell Test Book", "author": "Shell Author", "year": 2024}')
write_test_result "POST /books (Add test book)" "$command" "$response"

# Get the ID of the newly created book
book_id=$(echo "$response" | grep -o '"id":[0-9]*' | cut -d':' -f2)

# Test 4: Get single book
command="curl -s -X GET $BASE_URL/books/$book_id"
response=$(curl -s -X GET "$BASE_URL/books/$book_id")
write_test_result "GET /books/$book_id (Get test book)" "$command" "$response"

# Test 5: Update book
command="curl -s -X PUT $BASE_URL/books/$book_id -H 'Content-Type: application/json' -d '{\"title\": \"Updated Shell Test Book\", \"author\": \"Shell Author\", \"year\": 2025}'"
response=$(curl -s -X PUT "$BASE_URL/books/$book_id" -H "Content-Type: application/json" -d '{"title": "Updated Shell Test Book", "author": "Shell Author", "year": 2025}')
write_test_result "PUT /books/$book_id (Update test book)" "$command" "$response"

# Test 6: LangChain Simple Invoke
echo "Testing LangChain Endpoints..."
command="curl -s -X POST $BASE_URL/llm/simple-invoke -H 'Content-Type: application/json' -d '{\"message\": \"Hello from shell script!\"}'"
response=$(curl -s -X POST "$BASE_URL/llm/simple-invoke" -H "Content-Type: application/json" -d '{"message": "Hello from shell script!"}')
write_test_result "POST /llm/simple-invoke" "$command" "$response"

# Test 7: Embed PDFs
command="curl -s -X POST $BASE_URL/llm/embed-pdfs -H 'Content-Type: application/json' -d '{\"paths\": [\"sample.pdf\"]}'"
response=$(curl -s -X POST "$BASE_URL/llm/embed-pdfs" -H "Content-Type: application/json" -d '{"paths": ["sample.pdf"]}')
write_test_result "POST /llm/embed-pdfs" "$command" "$response"

# Test 8: Vector Search
command="curl -s -X POST $BASE_URL/llm/vector-search -H 'Content-Type: application/json' -d '{\"query\": \"Flask API\"}'"
response=$(curl -s -X POST "$BASE_URL/llm/vector-search" -H "Content-Type: application/json" -d '{"query": "Flask API"}')
write_test_result "POST /llm/vector-search" "$command" "$response"

# Test 9: Retrieval Answer
command="curl -s -X POST $BASE_URL/llm/retrieval-answer -H 'Content-Type: application/json' -d '{\"question\": \"What features are mentioned?\"}'"
response=$(curl -s -X POST "$BASE_URL/llm/retrieval-answer" -H "Content-Type: application/json" -d '{"question": "What features are mentioned?"}')
write_test_result "POST /llm/retrieval-answer" "$command" "$response"

# Test 10: React Agent
command="curl -s -X POST $BASE_URL/llm/react-agent -H 'Content-Type: application/json' -d '{\"message\": \"Count words in: Hello world shell test\"}'"
response=$(curl -s -X POST "$BASE_URL/llm/react-agent" -H "Content-Type: application/json" -d '{"message": "Count words in: Hello world shell test"}')
write_test_result "POST /llm/react-agent" "$command" "$response"

# Test 11: Delete test book
command="curl -s -X DELETE $BASE_URL/books/$book_id"
response=$(curl -s -X DELETE "$BASE_URL/books/$book_id")
write_test_result "DELETE /books/$book_id (Cleanup)" "$command" "$response"

# Test 12: Error Handling - Invalid LLM request
command="curl -s -X POST $BASE_URL/llm/simple-invoke -H 'Content-Type: application/json' -d '{}'"
response=$(curl -s -X POST "$BASE_URL/llm/simple-invoke" -H "Content-Type: application/json" -d '{}')
write_test_result "POST /llm/simple-invoke (Error case)" "$command" "$response"

# Test 13: Error Handling - Empty embed-pdfs
command="curl -s -X POST $BASE_URL/llm/embed-pdfs -H 'Content-Type: application/json' -d '{}'"
response=$(curl -s -X POST "$BASE_URL/llm/embed-pdfs" -H "Content-Type: application/json" -d '{}')
write_test_result "POST /llm/embed-pdfs (Error case)" "$command" "$response"

echo ""
echo "================================="
echo "All tests completed!"
echo "Shell results saved to: $RESULTS_FILE"
echo "================================="
