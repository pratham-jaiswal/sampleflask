# Flask Book + LangChain API

Simple Flask application that now includes:

- SQLite CRUD API using SQLAlchemy & Marshmallow
- LangChain v0.3 + LangGraph v0.2 demo endpoints (LLM calls, FAISS embeddings, retrieval, ReAct agent)

## Setup

1. Create virtual environment:
```bash
python -m venv venv
venv\Scripts\activate  # Windows
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. Provide your OpenAI credentials (either via `.env` or shell variables).  
`app.py` auto-loads `.env` thanks to `python-dotenv`.

PowerShell example:
```powershell
$env:OPENAI_API_KEY="sk-your-key"
# Optional overrides
$env:OPENAI_MODEL="gpt-4o-mini"
$env:OPENAI_EMBED_MODEL="text-embedding-3-small"
```

4. Run the app:
```bash
python app.py
```

The app runs at `http://127.0.0.1:5000`

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | API info |
| GET | `/books` | Get all books |
| GET | `/books/<id>` | Get a book |
| POST | `/books` | Add a book |
| PUT | `/books/<id>` | Update a book |
| DELETE | `/books/<id>` | Delete a book |
| POST | `/llm/simple-invoke` | Simple ChatGPT-style response with system + human msg |
| POST | `/llm/embed-pdfs` | Load PDF paths, chunk, embed via OpenAI embeddings + FAISS |
| POST | `/llm/vector-search` | Similarity search over the shared FAISS store |
| POST | `/llm/retrieval-answer` | Retrieval-Augmented QA chain on stored vectors |
| POST | `/llm/react-agent` | LangGraph ReAct agent with sample tool usage |

## Testing the Book API

Run the Flask app first:
```bash
python app.py
```

Then test all endpoints with the provided scripts:

**PowerShell (Windows):**
```powershell
.\test_api.ps1
```

**Batch file (Windows):**
```cmd
test_api.bat
```

**Bash script (Linux/Mac):**
```bash
chmod +x test_api.sh
./test_api.sh
```

## Example cURL Requests

**Add a book**
```bash
curl -X POST http://127.0.0.1:5000/books \
  -H "Content-Type: application/json" \
  -d "{\"title\": \"The Great Gatsby\", \"author\": \"F. Scott Fitzgerald\", \"year\": 1925}"
```

**Simple LLM invocation**
```bash
curl -X POST http://127.0.0.1:5000/llm/simple-invoke \
  -H "Content-Type: application/json" \
  -d "{\"system\": \"You summarize in one sentence.\", \"message\": \"Explain FAISS.\"}"
```

**Embed local PDFs into FAISS**
```bash
curl -X POST http://127.0.0.1:5000/llm/embed-pdfs \
  -H "Content-Type: application/json" \
  -d "{\"paths\": [\"C:/docs/sample.pdf\"], \"chunk_size\": 800, \"chunk_overlap\": 150}"
```

**Vector search**
```bash
curl -X POST http://127.0.0.1:5000/llm/vector-search \
  -H "Content-Type: application/json" \
  -d "{\"query\": \"What are the key findings?\", \"k\": 3}"
```

**Retrieval QA**
```bash
curl -X POST http://127.0.0.1:5000/llm/retrieval-answer \
  -H "Content-Type: application/json" \
  -d "{\"question\": \"Summarize the safety section.\", \"k\": 4}"
```

**LangGraph ReAct agent**
```bash
curl -X POST http://127.0.0.1:5000/llm/react-agent \
  -H "Content-Type: application/json" \
  -d "{\"message\": \"How many words are in 'LangChain makes RAG easy'?\"}"
```

## Project Structure

- `app.py` - Main Flask application with CRUD + LangChain endpoints
- `models.py` - SQLAlchemy database models
- `schemas.py` - Marshmallow schemas for JSON serialization
- `test_api.ps1` / `.bat` / `.sh` - Book API smoke tests
- `library.db` - SQLite database (created automatically)

