# Comprehensive Test Script for Flask Book + LangChain API
# Make sure the Flask app is running on http://127.0.0.1:5000

$BASE_URL = "http://127.0.0.1:5000"
$RESULTS_FILE = "test_results.txt"

# Clear previous results
"" | Out-File -FilePath $RESULTS_FILE -Encoding UTF8

function Write-Test-Result {
    param([string]$testName, [string]$command, [string]$response, [string]$status = "PASS")

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $result = @"
================================================================================
TEST: $testName
TIMESTAMP: $timestamp
STATUS: $status
COMMAND: $command
RESPONSE:
$response

"@

    Write-Host $result -ForegroundColor Green
    $result | Out-File -FilePath $RESULTS_FILE -Append -Encoding UTF8
}

Write-Host "=================================" -ForegroundColor Cyan
Write-Host "Comprehensive Flask API Testing" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

# Test 1: Home endpoint
Write-Host "Testing Home Endpoint..." -ForegroundColor Yellow
$command = "curl -X GET $BASE_URL/"
try {
    $response = Invoke-WebRequest -Uri "$BASE_URL/" -Method GET
    Write-Test-Result "GET / (Home)" $command $response.Content
} catch {
    Write-Test-Result "GET / (Home)" $command $_.Exception.Message "FAIL"
}

# Test 2: Get all books (initial state)
Write-Host "Testing Books CRUD..." -ForegroundColor Yellow
$command = "curl -X GET $BASE_URL/books"
try {
    $response = Invoke-WebRequest -Uri "$BASE_URL/books" -Method GET
    Write-Test-Result "GET /books (Initial state)" $command $response.Content
} catch {
    Write-Test-Result "GET /books (Initial state)" $command $_.Exception.Message "FAIL"
}

# Test 3: Add test book
$command = "curl -X POST $BASE_URL/books -H 'Content-Type: application/json' -d '{\`"title\`": \`"Test Book\`", \`"author\`": \`"Test Author\`", \`"year\`": 2024}'"
try {
    $jsonBody = '{"title": "Test Book", "author": "Test Author", "year": 2024}'
    $response = Invoke-WebRequest -Uri "$BASE_URL/books" -Method POST -Body $jsonBody -ContentType "application/json"
    Write-Test-Result "POST /books (Add test book)" $command $response.Content
} catch {
    Write-Test-Result "POST /books (Add test book)" $command $_.Exception.Message "FAIL"
}

# Test 4: Get single book
$command = "curl -X GET $BASE_URL/books/5"
try {
    $response = Invoke-WebRequest -Uri "$BASE_URL/books/5" -Method GET
    Write-Test-Result "GET /books/5 (Get test book)" $command $response.Content
} catch {
    Write-Test-Result "GET /books/5 (Get test book)" $command $_.Exception.Message "FAIL"
}

# Test 5: Update book
$command = "curl -X PUT $BASE_URL/books/5 -H 'Content-Type: application/json' -d '{\`"title\`": \`"Updated Test Book\`", \`"author\`": \`"Test Author\`", \`"year\`": 2025}'"
try {
    $jsonBody = '{"title": "Updated Test Book", "author": "Test Author", "year": 2025}'
    $response = Invoke-WebRequest -Uri "$BASE_URL/books/5" -Method PUT -Body $jsonBody -ContentType "application/json"
    Write-Test-Result "PUT /books/5 (Update test book)" $command $response.Content
} catch {
    Write-Test-Result "PUT /books/5 (Update test book)" $command $_.Exception.Message "FAIL"
}

# Test 6: LangChain Simple Invoke
Write-Host "Testing LangChain Endpoints..." -ForegroundColor Yellow
$command = "curl -X POST $BASE_URL/llm/simple-invoke -H 'Content-Type: application/json' -d '{\`"message\`": \`"Hello, how are you?\`"}'"
try {
    $jsonBody = '{"message": "Hello, how are you?"}'
    $response = Invoke-WebRequest -Uri "$BASE_URL/llm/simple-invoke" -Method POST -Body $jsonBody -ContentType "application/json"
    Write-Test-Result "POST /llm/simple-invoke" $command $response.Content
} catch {
    Write-Test-Result "POST /llm/simple-invoke" $command $_.Exception.Message "FAIL"
}

# Test 7: Embed PDFs (requires sample.pdf to exist)
$command = "curl -X POST $BASE_URL/llm/embed-pdfs -H 'Content-Type: application/json' -d '{\`"paths\`": [\`"sample.pdf\`"]}'"
try {
    $jsonBody = '{"paths": ["sample.pdf"]}'
    $response = Invoke-WebRequest -Uri "$BASE_URL/llm/embed-pdfs" -Method POST -Body $jsonBody -ContentType "application/json"
    Write-Test-Result "POST /llm/embed-pdfs" $command $response.Content
} catch {
    Write-Test-Result "POST /llm/embed-pdfs" $command $_.Exception.Message "FAIL"
}

# Test 8: Vector Search
$command = "curl -X POST $BASE_URL/llm/vector-search -H 'Content-Type: application/json' -d '{\`"query\`": \`"Flask API\`"}'"
try {
    $jsonBody = '{"query": "Flask API"}'
    $response = Invoke-WebRequest -Uri "$BASE_URL/llm/vector-search" -Method POST -Body $jsonBody -ContentType "application/json"
    Write-Test-Result "POST /llm/vector-search" $command $response.Content
} catch {
    Write-Test-Result "POST /llm/vector-search" $command $_.Exception.Message "FAIL"
}

# Test 9: Retrieval Answer
$command = "curl -X POST $BASE_URL/llm/retrieval-answer -H 'Content-Type: application/json' -d '{\`"question\`": \`"What features are mentioned?\`"}'"
try {
    $jsonBody = '{"question": "What features are mentioned?"}'
    $response = Invoke-WebRequest -Uri "$BASE_URL/llm/retrieval-answer" -Method POST -Body $jsonBody -ContentType "application/json"
    Write-Test-Result "POST /llm/retrieval-answer" $command $response.Content
} catch {
    Write-Test-Result "POST /llm/retrieval-answer" $command $_.Exception.Message "FAIL"
}

# Test 10: React Agent
$command = "curl -X POST $BASE_URL/llm/react-agent -H 'Content-Type: application/json' -d '{\`"message\`": \`"Count words in: Hello world test\`"}'"
try {
    $jsonBody = '{"message": "Count words in: Hello world test"}'
    $response = Invoke-WebRequest -Uri "$BASE_URL/llm/react-agent" -Method POST -Body $jsonBody -ContentType "application/json"
    Write-Test-Result "POST /llm/react-agent" $command $response.Content
} catch {
    Write-Test-Result "POST /llm/react-agent" $command $_.Exception.Message "FAIL"
}

# Test 11: Delete test book
$command = "curl -X DELETE $BASE_URL/books/5"
try {
    $response = Invoke-WebRequest -Uri "$BASE_URL/books/5" -Method DELETE
    Write-Test-Result "DELETE /books/5 (Cleanup)" $command $response.Content
} catch {
    Write-Test-Result "DELETE /books/5 (Cleanup)" $command $_.Exception.Message "FAIL"
}

# Test 12: Error Handling - Invalid LLM request
$command = "curl.exe -s -X POST $BASE_URL/llm/simple-invoke -H 'Content-Type: application/json' -d '{}'"
try {
    $jsonBody = '{}'
    $response = Invoke-WebRequest -Uri "$BASE_URL/llm/simple-invoke" -Method POST -Body $jsonBody -ContentType "application/json"
    Write-Test-Result "POST /llm/simple-invoke (Error case)" $command $response.Content
} catch {
    # Use curl to get the actual error response since PowerShell doesn't capture 4xx response bodies properly
    try {
        $curlResponse = & curl.exe -s -X POST "$BASE_URL/llm/simple-invoke" -H "Content-Type: application/json" -d "{}"
        Write-Test-Result "POST /llm/simple-invoke (Error case)" $command $curlResponse
    } catch {
        Write-Test-Result "POST /llm/simple-invoke (Error case)" $command "Failed to capture error response" "FAIL"
    }
}

# Test 13: Error Handling - Empty embed-pdfs
$command = "curl.exe -s -X POST $BASE_URL/llm/embed-pdfs -H 'Content-Type: application/json' -d '{}'"
try {
    $jsonBody = '{}'
    $response = Invoke-WebRequest -Uri "$BASE_URL/llm/embed-pdfs" -Method POST -Body $jsonBody -ContentType "application/json"
    Write-Test-Result "POST /llm/embed-pdfs (Error case)" $command $response.Content
} catch {
    try {
        $curlResponse = & curl.exe -s -X POST "$BASE_URL/llm/embed-pdfs" -H "Content-Type: application/json" -d "{}"
        Write-Test-Result "POST /llm/embed-pdfs (Error case)" $command $curlResponse
    } catch {
        Write-Test-Result "POST /llm/embed-pdfs (Error case)" $command "Failed to capture error response" "FAIL"
    }
}

Write-Host ""
Write-Host "=================================" -ForegroundColor Cyan
Write-Host "All tests completed!" -ForegroundColor Cyan
Write-Host "Results saved to: $RESULTS_FILE" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
