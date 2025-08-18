#!/bin/zsh

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_message() {
    echo -e "${2}${1}${NC}"
}

# Function to wait for service health
wait_for_service_health() {
    local service_name=$1
    local max_attempts=60
    local attempt=1
    
    print_message "Waiting for $service_name to be healthy..." $YELLOW
    
    while [ $attempt -le $max_attempts ]; do
        if docker-compose ps $service_name | grep -q "healthy"; then
            print_message "$service_name is healthy!" $GREEN
            return 0
        fi
        
        # Special handling for kafka_ui - check if it's accessible externally
        if [ "$service_name" = "kafka_ui" ]; then
            if curl -s http://localhost:8080 > /dev/null 2>&1; then
                print_message "$service_name is responding (accessible via HTTP)!" $GREEN
                return 0
            fi
        fi
        
        if [ $((attempt % 10)) -eq 0 ]; then
            print_message "Still waiting for $service_name... (attempt $attempt/$max_attempts)" $YELLOW
        fi
        
        sleep 2
        attempt=$((attempt + 1))
    done
    
    print_message "ERROR: $service_name failed to become healthy within $((max_attempts * 2)) seconds" $RED
    return 1
}

# Check if Docker is running
print_message "Checking Docker status..." $BLUE
if ! docker info > /dev/null 2>&1; then
    print_message "ERROR: Docker is not running. Please start Docker first." $RED
    exit 1
fi

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null; then
    print_message "ERROR: docker-compose is not installed or not in PATH" $RED
    exit 1
fi

# Pull the necessary images
print_message "Pulling necessary Docker images..." $BLUE
docker-compose pull

# Start services
print_message "Starting services..." $BLUE
docker-compose up -d

# Wait for services to be healthy
wait_for_service_health "zookeeper"
wait_for_service_health "kafka"
wait_for_service_health "kafka_ui"

print_message "All services are running and healthy!" $GREEN

# Show service status
print_message "Service Status:" $BLUE
docker-compose ps

# Display connection information
print_message "\n🎉 Kafka Setup Complete!" $GREEN
print_message "📊 Kafka UI: http://localhost:8080" $BLUE
print_message "🔗 Kafka Broker: localhost:9092" $BLUE
print_message "🏪 Zookeeper: localhost:2181" $BLUE

# Optional: Create topics if requested
if [ "$1" = "--create-topics" ] || [ "$1" = "-t" ]; then
    print_message "\nCreating example topics..." $YELLOW
    
    # Wait a bit more for Kafka to be fully ready for topic operations
    sleep 5
    
    # Create example topics
    docker exec kafka kafka-topics --create \
        --topic "test-topic" \
        --bootstrap-server localhost:9093 \
        --partitions 3 \
        --replication-factor 1 \
        --if-not-exists
        
    docker exec kafka kafka-topics --create \
        --topic "events" \
        --bootstrap-server localhost:9093 \
        --partitions 1 \
        --replication-factor 1 \
        --if-not-exists
    
    print_message "Example topics created: test-topic, events" $GREEN
fi

# Open Kafka UI in browser (only on macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    print_message "\nOpening Kafka UI in browser..." $BLUE
    sleep 2
    open http://localhost:8080
fi

print_message "\n✅ Setup complete! Use 'docker-compose logs -f' to view logs." $GREEN
print_message "💡 Use '$0 --create-topics' to create example topics next time." $YELLOW
