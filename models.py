"""
Database Models using SQLAlchemy
"""
from flask_sqlalchemy import SQLAlchemy

# Initialize SQLAlchemy
db = SQLAlchemy()


class Book(db.Model):
    """Book model - represents a book in our library"""
    
    __tablename__ = 'books'
    
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(100), nullable=False)
    author = db.Column(db.String(100), nullable=False)
    year = db.Column(db.Integer)
    
    def __repr__(self):
        return f'<Book {self.title}>'

