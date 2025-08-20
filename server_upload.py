import sqlite3
import hashlib
import os
from flask import Flask, request, jsonify
import json

# --- App & DB Configuration ---
app = Flask(__name__)
DATABASE = 'server_demo.db'
UPLOAD_FOLDER = 'uploads'
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# --- Database Helper Functions ---

def get_db():
    """Opens a new database connection."""
    conn = sqlite3.connect(DATABASE)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    """Initializes the database and creates tables if they don't exist."""
    with app.app_context():
        db = get_db()
        cursor = db.cursor()
        # Create users table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                username TEXT UNIQUE NOT NULL,
                password_hash TEXT NOT NULL
            )
        ''')
        # Create video_analyses table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS video_analyses (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                video_name TEXT NOT NULL,
                analysis_result TEXT NOT NULL,
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users (id)
            )
        ''')
        db.commit()
        cursor.close()
        db.close()
        print("Database initialized.")

def hash_password(password):
    """Hashes a password using SHA256."""
    return hashlib.sha256(password.encode('utf-8')).hexdigest()

# --- API Endpoints ---

@app.route('/api/register', methods=['POST'])
def register():
    """Registers a new user."""
    data = request.get_json()
    if not data or 'username' not in data or 'password' not in data:
        return jsonify({'status': 'error', 'message': 'Missing username or password'}), 400

    username = data['username']
    password = data['password']
    
    db = get_db()
    cursor = db.cursor()
    
    # Check if user already exists
    cursor.execute('SELECT id FROM users WHERE username = ?', (username,))
    if cursor.fetchone():
        cursor.close()
        db.close()
        return jsonify({'status': 'error', 'message': 'Username already exists'}), 409

    # Insert new user
    password_h = hash_password(password)
    cursor.execute('INSERT INTO users (username, password_hash) VALUES (?, ?)', (username, password_h))
    db.commit()
    
    user_id = cursor.lastrowid
    cursor.close()
    db.close()
    
    return jsonify({'status': 'success', 'message': 'User registered successfully', 'user_id': user_id}), 201

@app.route('/api/login', methods=['POST'])
def login():
    """Logs in a user."""
    data = request.get_json()
    if not data or 'username' not in data or 'password' not in data:
        return jsonify({'status': 'error', 'message': 'Missing username or password'}), 400

    username = data['username']
    password = data['password']
    password_h = hash_password(password)

    db = get_db()
    cursor = db.cursor()
    
    cursor.execute('SELECT * FROM users WHERE username = ?', (username,))
    user = cursor.fetchone()
    
    if user and user['password_hash'] == password_h:
        cursor.close()
        db.close()
        return jsonify({
            'status': 'success', 
            'message': 'Login successful', 
            'user_id': user['id'],
            'username': user['username']
        }), 200
    else:
        cursor.close()
        db.close()
        return jsonify({'status': 'error', 'message': 'Invalid username or password'}), 401

@app.route('/api/upload', methods=['POST'])
def upload_file():
    """Uploads a video for analysis and associates it with a user."""
    # Check if user_id is provided
    if 'user_id' not in request.form:
        return jsonify({'status': 'error', 'message': 'user_id is required'}), 400
    user_id = request.form['user_id']

    # Check if the post request has the file part
    if 'file' not in request.files:
        return jsonify({'status': 'error', 'message': 'No file part in the request'}), 400
    file = request.files['file']

    if file.filename == '':
        return jsonify({'status': 'error', 'message': 'No file selected for uploading'}), 400

    if file:
        filename = file.filename
        save_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        file.save(save_path)

        # --- Simulate Analysis ---
        # In a real application, you would call your analysis logic here.
        # For this demo, we'll just create a dummy result.
        analysis_result = {
            "file_path": save_path,
            "summary": f"Analysis of {filename} complete.",
            "score": 95.5,
            "highlights": [
                {"timestamp": "00:15", "event": "Goal"},
                {"timestamp": "00:48", "event": "Foul"}
            ]
        }
        analysis_result_str = json.dumps(analysis_result)
        
        # --- Store analysis result in the database ---
        db = get_db()
        cursor = db.cursor()
        cursor.execute(
            'INSERT INTO video_analyses (user_id, video_name, analysis_result) VALUES (?, ?, ?)',
            (user_id, filename, analysis_result_str)
        )
        db.commit()
        cursor.close()
        db.close()

        return jsonify({
            'status': 'success',
            'message': f"File '{filename}' uploaded and analyzed successfully.",
            'data': analysis_result
        }), 200

    return jsonify({'status': 'error', 'message': 'An unexpected error occurred'}), 500

# --- Main Execution ---
if __name__ == '__main__':
    init_db()  # Initialize the database on startup
    # To run this, use: flask --app server_upload run
    # Or for development:
    app.run(host='0.0.0.0', port=8000, debug=True)