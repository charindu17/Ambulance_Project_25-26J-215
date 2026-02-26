import uuid

import bcrypt

def hash_password(password):
    """Hash a password using bcrypt"""
    salt = bcrypt.gensalt()
    return bcrypt.hashpw(password.encode('utf-8'), salt).decode('utf-8')

def verify_password(password, hashed):
    """Verify a password against its hash"""
    return bcrypt.checkpw(password.encode('utf-8'), hashed.encode('utf-8'))

def generate_filename(original_filename):
    ext = original_filename.rsplit('.', 1)[1].lower() if '.' in original_filename else ''
    return f"{uuid.uuid4().hex}.{ext}" if ext else uuid.uuid4().hex

def allowed_file(filename, allowed_extensions={'pdf', 'png', 'jpg', 'jpeg', 'doc', 'docx'}):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in allowed_extensions