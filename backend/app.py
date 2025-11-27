# Import necessary libraries
from flask import Flask, request, jsonify
# Flask: Web framework to create API endpoints
# request: Handle incoming HTTP requests
# jsonify: Convert Python data to JSON format

from flask_cors import CORS
# CORS: Allow frontend (different domain) to talk to backend

import psycopg2
# psycopg2: Library to connect Python to PostgreSQL database

from psycopg2.extras import RealDictCursor
# RealDictCursor: Return database rows as dictionaries (easier to work with)

import os
# os: Access environment variables (like database password)

# Create Flask application
app = Flask(__name__)

# Enable CORS - allows frontend to make requests to this backend
CORS(app)

# Function to connect to the database
def get_db_connection():
    # Get database connection details from environment variables
    # Environment variables are secure ways to store sensitive info
    conn = psycopg2.connect(
        host=os.environ.get('DB_HOST', 'localhost'),
        # DB_HOST: Database server address (from environment, defaults to localhost)
        
        database=os.environ.get('DB_NAME', 'blogdb'),
        # DB_NAME: Name of the database
        
        user=os.environ.get('DB_USER', 'postgres'),
        # DB_USER: Database username
        
        password=os.environ.get('DB_PASSWORD', 'password'),
        # DB_PASSWORD: Database password (MUST be in environment variables for security)
        
        cursor_factory=RealDictCursor
        # Return results as dictionaries
    )
    return conn

# Initialize database table when app starts
def init_db():
    # Connect to database
    conn = get_db_connection()
    cursor = conn.cursor()
    
    # Create posts table if it doesn't exist
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS posts (
            id SERIAL PRIMARY KEY,
            title VARCHAR(200) NOT NULL,
            content TEXT NOT NULL,
            author VARCHAR(100) NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    # SERIAL: Auto-incrementing number for post IDs
    # VARCHAR: Text with max length
    # TEXT: Unlimited text
    # TIMESTAMP: Date and time
    
    # Save changes
    conn.commit()
    
    # Close connections
    cursor.close()
    conn.close()

# API Endpoint: Health check (verify API is running)
@app.route('/api/health', methods=['GET'])
# @app.route: Creates an endpoint at /api/health
# methods=['GET']: Only accept GET requests
def health_check():
    return jsonify({"status": "healthy"}), 200
    # Return JSON with 200 status code (success)

# API Endpoint: Get all blog posts
@app.route('/api/posts', methods=['GET'])
def get_posts():
    conn = get_db_connection()
    cursor = conn.cursor()
    
    # Query database for all posts, newest first
    cursor.execute('SELECT * FROM posts ORDER BY created_at DESC')
    posts = cursor.fetchall()
    # fetchall(): Get all rows from query result
    
    cursor.close()
    conn.close()
    
    # Return posts as JSON
    return jsonify(posts), 200

# API Endpoint: Get single post by ID
@app.route('/api/posts/<int:post_id>', methods=['GET'])
# <int:post_id>: URL parameter, must be an integer
def get_post(post_id):
    conn = get_db_connection()
    cursor = conn.cursor()
    
    # Query for specific post
    cursor.execute('SELECT * FROM posts WHERE id = %s', (post_id,))
    post = cursor.fetchone()
    # fetchone(): Get one row
    
    cursor.close()
    conn.close()
    
    if post:
        return jsonify(post), 200
    else:
        # Return 404 if post not found
        return jsonify({"error": "Post not found"}), 404

# API Endpoint: Create new post
@app.route('/api/posts', methods=['POST'])
def create_post():
    # Get JSON data from request body
    data = request.get_json()
    
    # Extract fields
    title = data.get('title')
    content = data.get('content')
    author = data.get('author')
    
    # Validate required fields
    if not title or not content or not author:
        return jsonify({"error": "Missing required fields"}), 400
    
    conn = get_db_connection()
    cursor = conn.cursor()
    
    # Insert new post into database
    cursor.execute(
        'INSERT INTO posts (title, content, author) VALUES (%s, %s, %s) RETURNING id',
        (title, content, author)
    )
    # RETURNING id: Get the ID of the newly created post
    
    post_id = cursor.fetchone()['id']
    
    # Save changes
    conn.commit()
    cursor.close()
    conn.close()
    
    return jsonify({"id": post_id, "message": "Post created"}), 201
    # 201: Created successfully

# API Endpoint: Update existing post
@app.route('/api/posts/<int:post_id>', methods=['PUT'])
def update_post(post_id):
    data = request.get_json()
    
    title = data.get('title')
    content = data.get('content')
    author = data.get('author')
    
    if not title or not content or not author:
        return jsonify({"error": "Missing required fields"}), 400
    
    conn = get_db_connection()
    cursor = conn.cursor()
    
    # Update post in database
    cursor.execute(
        'UPDATE posts SET title = %s, content = %s, author = %s WHERE id = %s',
        (title, content, author, post_id)
    )
    
    conn.commit()
    cursor.close()
    conn.close()
    
    return jsonify({"message": "Post updated"}), 200

# API Endpoint: Delete post
@app.route('/api/posts/<int:post_id>', methods=['DELETE'])
def delete_post(post_id):
    conn = get_db_connection()
    cursor = conn.cursor()
    
    # Delete post from database
    cursor.execute('DELETE FROM posts WHERE id = %s', (post_id,))
    
    conn.commit()
    cursor.close()
    conn.close()
    
    return jsonify({"message": "Post deleted"}), 200

# Run the application
if __name__ == '__main__':
    # Initialize database when app starts
    init_db()
    
    # Run Flask server
    app.run(host='0.0.0.0', port=5000, debug=False)
    # host='0.0.0.0': Accept connections from any IP
    # port=5000: Run on port 5000
    # debug=False: Don't show detailed errors (security best practice)