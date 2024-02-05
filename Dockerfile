# Use an official Python runtime as a parent image
FROM python:3.10

# Set the working directory in the container
WORKDIR /opt

# Copy the current directory contents into the container at /opt
COPY . .

# Install any needed packages specified in requirements.txt
COPY requirements.txt .
RUN pip install --upgrade pip && \
    pip install -r requirements.txt

# Make port 8000 available to the world outside this container
EXPOSE 8000

# Define environment variable to run FastAPI in production mode
ENV UVICORN_WORKERS=3

# Run uvicorn when the container launches
ENTRYPOINT ["uvicorn", "main:app", "--host=0.0.0.0", "--port=8000", "--workers", "3"]
