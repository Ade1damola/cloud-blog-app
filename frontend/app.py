# Import libraries
from flask import Flask, render_template, request, redirect, url_for
# Flask: Web framework
# render_template: Display HTML files
# request: Handle form submissions
# redirect, url_for: Navigate between pages

import requests
# requests: Make HTTP calls to backend API

import os
# os: Access environment variables

# Create Flask app
app = Flask(__name__)

# Get backend API URL from environment variable
BACKEND_URL = os.environ.get('BACKEND_URL', 'http://localhost:5000')

# Home page - shows all blog posts
@app.route('/')
def index():
    try:
        # Call backend API to get all posts
        response = requests.get(f'{BACKEND_URL}/api/posts')
        # f-string: Insert variable into string
        
        # Convert response to JSON
        posts = response.json()
    except:
        # If backend is down, show empty list
        posts = []
    
    # Render index.html and pass posts to it
    return render_template('index.html', posts=posts)

# Create post page
@app.route('/create', methods=['GET', 'POST'])
def create():
    # If user submitted the form (POST request)
    if request.method == 'POST':
        # Get form data
        title = request.form['title']
        content = request.form['content']
        author = request.form['author']
        
        # Send data to backend API
        requests.post(f'{BACKEND_URL}/api/posts', json={
            'title': title,
            'content': content,
            'author': author
        })
        
        # Redirect back to home page
        return redirect(url_for('index'))
    
    # If just visiting page (GET request), show form
    return render_template('create.html')

# Edit post page
@app.route('/edit/<int:post_id>', methods=['GET', 'POST'])
def edit(post_id):
    if request.method == 'POST':
        # Get form data
        title = request.form['title']
        content = request.form['content']
        author = request.form['author']
        
        # Update post via backend API
        requests.put(f'{BACKEND_URL}/api/posts/{post_id}', json={
            'title': title,
            'content': content,
            'author': author
        })
        
        return redirect(url_for('index'))
    
    # Get existing post data to pre-fill form
    response = requests.get(f'{BACKEND_URL}/api/posts/{post_id}')
    post = response.json()
    
    return render_template('edit.html', post=post)

# Delete post
@app.route('/delete/<int:post_id>')
def delete(post_id):
    # Call backend API to delete post
    requests.delete(f'{BACKEND_URL}/api/posts/{post_id}')
    
    return redirect(url_for('index'))

# Run the app
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=False)
    # Port 8080: Different from backend (5000)