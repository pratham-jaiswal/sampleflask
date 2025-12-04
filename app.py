"""
Simple Flask App with SQLite CRUD endpoints plus LangChain/LangGraph demos.
"""
import os
from pathlib import Path
from threading import Lock
from typing import Any, Dict, List, Optional

from dotenv import load_dotenv
from flask import Flask, jsonify, request
from langchain_classic.chains import (
    create_retrieval_chain,
    create_stuff_documents_chain
)
from langchain_community.document_loaders import PyPDFLoader
from langchain_community.vectorstores import FAISS
from langchain_core.messages import HumanMessage, SystemMessage
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.tools import tool
from langchain_openai import ChatOpenAI, OpenAIEmbeddings
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langgraph.prebuilt import create_react_agent

from models import Book, db
from schemas import book_schema, books_schema, ma

# Load environment variables from .env if present
load_dotenv()

# Create Flask app
app = Flask(__name__)

# Configure SQLite database
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///library.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

# Initialize extensions with app
db.init_app(app)
ma.init_app(app)


# Create tables before first request
with app.app_context():
    db.create_all()


# ===== LangChain / LangGraph globals =====
DEFAULT_CHAT_MODEL = os.getenv('OPENAI_MODEL', 'gpt-4o-mini')
DEFAULT_EMBED_MODEL = os.getenv('OPENAI_EMBED_MODEL', 'text-embedding-3-small')

VECTOR_STORE: Optional[FAISS] = None
CURRENT_EMBED_MODEL: Optional[str] = None
VECTOR_LOCK = Lock()


def build_chat_llm(model_name: Optional[str] = None, temperature: float = 0.2) -> ChatOpenAI:
    """Create a ChatOpenAI instance and surface configuration errors clearly."""
    try:
        return ChatOpenAI(model=model_name or DEFAULT_CHAT_MODEL, temperature=temperature)
    except Exception as exc:  # pragma: no cover - depends on external config
        raise RuntimeError(f'Unable to initialize ChatOpenAI: {exc}') from exc


def build_embeddings(model_name: Optional[str] = None) -> OpenAIEmbeddings:
    """Create an embeddings model with friendly error messages."""
    try:
        return OpenAIEmbeddings(model=model_name or DEFAULT_EMBED_MODEL)
    except Exception as exc:  # pragma: no cover - depends on external config
        raise RuntimeError(f'Unable to initialize OpenAIEmbeddings: {exc}') from exc


def load_pdf_chunks(paths: List[str], chunk_size: int, chunk_overlap: int) -> List[Any]:
    """Load PDFs into text chunks that FAISS can embed."""
    if chunk_size <= chunk_overlap:
        raise ValueError('chunk_size must be greater than chunk_overlap')

    chunks = []
    splitter = RecursiveCharacterTextSplitter(chunk_size=chunk_size, chunk_overlap=chunk_overlap)

    if not paths:
        raise ValueError('paths cannot be empty')

    for raw_path in paths:
        path = Path(raw_path).expanduser()
        if not path.exists():
            raise FileNotFoundError(f'File not found: {path}')

        loader = PyPDFLoader(str(path))
        docs = loader.load()
        for doc in docs:
            doc.metadata.setdefault('source', str(path))

        chunks.extend(splitter.split_documents(docs))

    return chunks


def vector_store_size(store: FAISS) -> int:
    """Return how many chunks are currently stored."""
    return len(getattr(store.docstore, '_dict', {}))


@tool
def text_stats(text: str) -> str:
    """Return quick statistics about the supplied text snippet."""
    words = len(text.split())
    return f'Characters: {len(text)}, Words: {words}'


AGENT_TOOLS = [text_stats]


# ============ ROUTES ============

@app.route('/')
def home():
    """Home route."""
    return jsonify({
        'message': 'Welcome to the Book + LangChain API!',
        'endpoints': {
            'GET /books': 'Get all books',
            'GET /books/<id>': 'Get a single book',
            'POST /books': 'Add a new book',
            'PUT /books/<id>': 'Update a book',
            'DELETE /books/<id>': 'Delete a book',
            'POST /llm/simple-invoke': 'Call an LLM with system & human messages',
            'POST /llm/embed-pdfs': 'Embed PDF files into a FAISS vector store',
            'POST /llm/vector-search': 'Search the FAISS vector store',
            'POST /llm/retrieval-answer': 'Retrieval QA chain over the vector store',
            'POST /llm/react-agent': 'Run a LangGraph ReAct agent with a sample tool'
        }
    })


@app.route('/books', methods=['GET'])
def get_books():
    """Get all books"""
    all_books = Book.query.all()
    return books_schema.jsonify(all_books)


@app.route('/books/<int:id>', methods=['GET'])
def get_book(id):
    """Get a single book by ID"""
    book = Book.query.get_or_404(id)
    return book_schema.jsonify(book)


@app.route('/books', methods=['POST'])
def add_book():
    """Add a new book"""
    data = request.get_json()
    
    new_book = Book(
        title=data['title'],
        author=data['author'],
        year=data.get('year')  # Optional field
    )
    
    db.session.add(new_book)
    db.session.commit()
    
    return book_schema.jsonify(new_book), 201


@app.route('/books/<int:id>', methods=['PUT'])
def update_book(id):
    """Update an existing book"""
    book = Book.query.get_or_404(id)
    data = request.get_json()
    
    book.title = data.get('title', book.title)
    book.author = data.get('author', book.author)
    book.year = data.get('year', book.year)
    
    db.session.commit()
    
    return book_schema.jsonify(book)


@app.route('/books/<int:id>', methods=['DELETE'])
def delete_book(id):
    """Delete a book"""
    book = Book.query.get_or_404(id)
    
    db.session.delete(book)
    db.session.commit()
    
    return jsonify({'message': f'Book "{book.title}" deleted successfully'})


@app.route('/llm/simple-invoke', methods=['POST'])
def simple_llm_invoke():
    """Simple ChatGPT-style invocation with system + human messages."""
    payload = request.get_json(silent=True) or {}
    user_message = payload.get('message')
    system_message = payload.get('system', 'You are a concise and helpful assistant.')
    model_name = payload.get('model')
    temperature = float(payload.get('temperature', 0.2))

    if not user_message:
        return jsonify({'error': 'message is required'}), 400

    try:
        llm = build_chat_llm(model_name=model_name, temperature=temperature)
        prompt = ChatPromptTemplate.from_messages([
            ('system', system_message),
            ('human', '{user_input}')
        ])
        chain = prompt | llm
        result = chain.invoke({'user_input': user_message})
    except RuntimeError as err:
        return jsonify({'error': str(err)}), 500

    return jsonify({'response': result.content})


@app.route('/llm/embed-pdfs', methods=['POST'])
def embed_pdfs():
    """Embed PDFs into (or append to) a shared FAISS vector store."""
    payload = request.get_json(silent=True) or {}
    paths = payload.get('paths', [])
    chunk_size = int(payload.get('chunk_size', 1000))
    chunk_overlap = int(payload.get('chunk_overlap', 150))
    embedding_model = payload.get('embedding_model')

    if not paths:
        return jsonify({'error': 'paths (list of PDF files) is required'}), 400

    try:
        chunks = load_pdf_chunks(paths, chunk_size, chunk_overlap)
    except (ValueError, FileNotFoundError) as err:
        return jsonify({'error': str(err)}), 400

    if not chunks:
        return jsonify({'error': 'No text chunks were produced from the supplied PDFs'}), 400

    try:
        embeddings = build_embeddings(embedding_model)
    except RuntimeError as err:
        return jsonify({'error': str(err)}), 500

    global VECTOR_STORE, CURRENT_EMBED_MODEL
    with VECTOR_LOCK:
        if VECTOR_STORE is None:
            VECTOR_STORE = FAISS.from_documents(chunks, embeddings)
            CURRENT_EMBED_MODEL = embedding_model or DEFAULT_EMBED_MODEL
        else:
            incoming_model = embedding_model or CURRENT_EMBED_MODEL
            if incoming_model != CURRENT_EMBED_MODEL:
                return jsonify({'error': 'Existing vector store uses a different embedding model.'}), 400
            VECTOR_STORE.add_documents(chunks)
        total_docs = vector_store_size(VECTOR_STORE)

    return jsonify({
        'indexed_chunks': len(chunks),
        'total_chunks': total_docs,
        'embedding_model': CURRENT_EMBED_MODEL,
        'paths': paths
    })


@app.route('/llm/vector-search', methods=['POST'])
def vector_search():
    """Run a similarity search over the FAISS vector store."""
    payload = request.get_json(silent=True) or {}
    query = payload.get('query')
    top_k = int(payload.get('k', 4))

    if not query:
        return jsonify({'error': 'query is required'}), 400

    if VECTOR_STORE is None:
        return jsonify({'error': 'Vector store empty. Call /llm/embed-pdfs first.'}), 400

    docs = VECTOR_STORE.similarity_search(query, k=top_k)
    results = [{'content': doc.page_content, 'metadata': doc.metadata} for doc in docs]
    return jsonify({'results': results})


@app.route('/llm/retrieval-answer', methods=['POST'])
def retrieval_answer():
    """Answer a question using retrieval augmented generation."""
    payload = request.get_json(silent=True) or {}
    question = payload.get('question')
    system_prompt = payload.get(
        'system',
        'You are a domain expert. Use only the provided context to answer.'
    )
    top_k = int(payload.get('k', 4))
    temperature = float(payload.get('temperature', 0.1))

    if not question:
        return jsonify({'error': 'question is required'}), 400
    if VECTOR_STORE is None:
        return jsonify({'error': 'Vector store empty. Call /llm/embed-pdfs first.'}), 400

    try:
        llm = build_chat_llm(temperature=temperature)
    except RuntimeError as err:
        return jsonify({'error': str(err)}), 500

    retriever = VECTOR_STORE.as_retriever(search_kwargs={'k': top_k})
    prompt = ChatPromptTemplate.from_messages([
        ('system', '{system_prompt}\n\nContext:\n{context}'),
        ('human', '{input}')
    ])
    doc_chain = create_stuff_documents_chain(llm, prompt)
    rag_chain = create_retrieval_chain(retriever, doc_chain)
    result: Dict[str, Any] = rag_chain.invoke({'input': question, 'system_prompt': system_prompt})

    context_payload = [
        {'content': doc.page_content, 'metadata': doc.metadata}
        for doc in result.get('context', [])
    ]

    return jsonify({
        'answer': result.get('answer'),
        'context': context_payload
    })


@app.route('/llm/react-agent', methods=['POST'])
def react_agent():
    """Run a LangGraph ReAct agent that can call a sample tool."""
    payload = request.get_json(silent=True) or {}
    user_message = payload.get('message')
    chat_history = payload.get('chat_history', [])
    system_prompt = payload.get(
        'system',
        'You are a thoughtful assistant. Decide when to use tools.'
    )
    temperature = float(payload.get('temperature', 0.0))

    if not user_message:
        return jsonify({'error': 'message is required'}), 400

    try:
        llm = build_chat_llm(temperature=temperature)
        agent_app = create_react_agent(
            model=llm,
            tools=AGENT_TOOLS,
            prompt=system_prompt
        )
        messages = chat_history
        messages.append(("user",user_message))
        agent_result = agent_app.invoke({'messages': messages})
        final_message = agent_result['messages'][-1].content
        tool_events = [
            {
                'tool': getattr(msg, 'name', getattr(msg, 'tool', 'unknown')),
                'content': getattr(msg, 'content', '')
            }
            for msg in agent_result['messages']
            if getattr(msg, 'type', '') == 'tool'
        ]
    except RuntimeError as err:
        return jsonify({'error': str(err)}), 500
    except Exception as exc:  # pragma: no cover - depends on external service
        return jsonify({'error': f'Agent execution failed: {exc}'}), 500

    messages.append(("ai",final_message))
    return jsonify({
        'messages': messages,
        'tool_events': tool_events
    })


# Run the app
if __name__ == '__main__':
    app.run(debug=True)

