# Use the official Python slim image from the Docker Hub
FROM python:3.9-slim

# Set the working directory
WORKDIR /app

# Copy requirements file and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code
COPY . .

# Environment variables
ENV PORT=8080

# Expose the port on which the app will run
EXPOSE 8080

# Run the application
CMD ["python", "app.py"]