"""
Marshmallow Schemas for serialization/deserialization
"""
from flask_marshmallow import Marshmallow

# Initialize Marshmallow
ma = Marshmallow()


class BookSchema(ma.Schema):
    """Schema for Book model - converts Book objects to/from JSON"""
    
    class Meta:
        # Fields to include in serialization
        fields = ('id', 'title', 'author', 'year')


# Single book schema
book_schema = BookSchema()

# Multiple books schema
books_schema = BookSchema(many=True)

