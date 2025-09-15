#!/bin/zsh

set -e  # Exit on any error

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"

# Change to the script directory to ensure relative paths work
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Function to print colored output
print_message() {
    echo -e ta"${2}${1}${NC}"
}

# Function to show usage
show_usage() {
    print_message "Kafka Docker Setup - Start Script" $BLUE
    print_message "Usage: $0 [options]" $YELLOW
    print_message "Options:" $NC
    print_message "  --create-topics, -t    Create example topics after startup" $NC
    print_message "  --open-browser, -b     Open browser automatically (default: no browser)" $NC
    print_message "  --help, -h             Show this help message" $NC
    print_message "" $NC
    print_message "This script starts the Kafka Docker environment:" $BLUE
    print_message "  • Starts all services (Zookeeper, Kafka, Kafka UI)" $NC
    print_message "  • Performs health checks and waits for readiness" $NC
    print_message "  • Displays connection information" $NC
    print_message "  • Optionally creates example topics" $NC
    print_message "" $NC
    print_message "Prerequisites:" $YELLOW
    print_message "  • Run './build_kafka.sh' first for initial setup" $NC
    print_message "  • Docker must be running" $NC
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

# Parse command line arguments
CREATE_TOPICS=false
OPEN_BROWSER=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --create-topics|-t)
            CREATE_TOPICS=true
            shift
            ;;
        --open-browser|-b)
            OPEN_BROWSER=true
            shift
            ;;
        --help|-h)
            show_usage
            exit 0
            ;;
        *)
            print_message "Unknown option: $1" $RED
            show_usage
            exit 1
            ;;
    esac
done

print_message "🚀 Starting Kafka Docker Environment..." $PURPLE

# Check if Docker is running
print_message "Checking Docker status..." $BLUE
if ! docker info > /dev/null 2>&1; then
    print_message "ERROR: Docker is not running. Please start Docker first." $RED
    exit 1
fi
print_message "✅ Docker is running" $GREEN

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null; then
    print_message "ERROR: docker-compose is not installed or not in PATH" $RED
    exit 1
fi
print_message "✅ docker-compose is available" $GREEN

# Check if images exist (suggest build if missing)
if ! docker images | grep -q "confluentinc/cp-kafka:7.4.0"; then
    print_message "⚠️  Kafka images not found. Run './build_kafka.sh' first." $YELLOW
    print_message "💡 Proceeding with image pull..." $BLUE
    docker-compose pull
else
    print_message "✅ Required images are available" $GREEN
fi

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
if [ "$CREATE_TOPICS" = true ]; then
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

# Open Kafka UI in browser (only on macOS and if requested)
if [[ "$OSTYPE" == "darwin"* ]] && [ "$OPEN_BROWSER" = true ]; then
    print_message "\nOpening Kafka UI in browser..." $BLUE
    sleep 2
    open http://localhost:8080
fi

print_message "\n✅ Kafka environment started successfully!" $GREEN
print_message "📋 Management Commands:" $BLUE
print_message "  • ./pause_kafka.sh        - Pause services (quick stop)" $NC
print_message "  • ./stop_kafka.sh         - Complete shutdown" $NC
print_message "  • ./monitor.sh status     - Check service health" $NC
print_message "  • ./list_topics.sh        - List topics" $NC
print_message "  • ./create_topic.sh <name> - Create new topic" $NC

if [ "$CREATE_TOPICS" = false ]; then
    print_message "\n💡 Use '$0 --create-topics' to create example topics." $YELLOW
fi
