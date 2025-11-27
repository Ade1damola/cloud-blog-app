# Start from Python 3.11 slim image
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Copy requirements and install
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code and templates
COPY app.py .
COPY templates/ templates/
COPY static/ static/

# Expose port 8080
EXPOSE 8080

# Run the application
CMD ["python", "app.py"]