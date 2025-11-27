# Start from Python 3.11 slim image (smaller size)
FROM python:3.11-slim

# Set working directory inside container
WORKDIR /app
# All subsequent commands run in /app directory

# Copy requirements file first (for caching)
COPY requirements.txt .
# Copying separately allows Docker to cache this layer

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt
# --no-cache-dir: Don't store cache (reduces image size)

# Copy application code
COPY app.py .

# Expose port 5000
EXPOSE 5000
# Documents which port the app uses

# Run the application
CMD ["python", "app.py"]
# CMD: Default command when container starts