#!/bin/zsh

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "Docker is not running. Please start Docker first."
    exit 1
fi

# Pull the necessary images
echo "Pulling necessary Docker images..."
docker-compose pull

# Start Kafka, Zookeeper, and the UI app (AKHQ)
echo "Starting services..."
docker-compose up --build -d

# Wait for services to be ready
echo "Waiting for Kafka and Zookeeper to be ready..."
sleep 15

# Open AKHQ UI in the default browser
echo "Opening AKHQ UI..."
open http://localhost:8080

echo "Kafka, Zookeeper, and AKHQ are now running."

# Create Kafka topics
echo "Creating Kafka topics..."
docker exec -it kafka /usr/bin/kafka-topics --create \
    --topic "fynd-json-gringotts-payment_status" \
    --bootstrap-server localhost:9093 \
    --partitions 1 \
    --replication-factor 1

echo "Kafka topic 'fynd-json-gringotts-payment_status' created successfully."
