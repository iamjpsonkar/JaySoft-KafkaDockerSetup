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
    echo -e "${2}${1}${NC}"
}

# Function to show usage
show_usage() {
    print_message "Kafka Docker Setup - Build Script" $BLUE
    print_message "Usage: $0 [options]" $YELLOW
    print_message "Options:" $NC
    print_message "  --force, -f     Force rebuild even if images exist" $NC
    print_message "  --clean, -c     Clean build (remove existing images first)" $NC
    print_message "  --help, -h      Show this help message" $NC
    print_message "" $NC
    print_message "This script builds and starts the Kafka Docker environment:" $BLUE
    print_message "  • Validates Docker and docker-compose availability" $NC
    print_message "  • Pulls/rebuilds necessary Docker images" $NC
    print_message "  • Creates data directories with proper permissions" $NC
    print_message "  • Validates docker-compose configuration" $NC
    print_message "  • Starts all services and waits for health checks" $NC
    print_message "  • Opens Kafka UI in browser (macOS)" $NC
}

# Parse command line arguments
FORCE_REBUILD=false
CLEAN_BUILD=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --force|-f)
            FORCE_REBUILD=true
            shift
            ;;
        --clean|-c)
            CLEAN_BUILD=true
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

print_message "🔨 Building Kafka Docker Environment..." $PURPLE

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

# Validate docker-compose.yml
print_message "Validating docker-compose configuration..." $BLUE
if ! docker-compose config > /dev/null 2>&1; then
    print_message "ERROR: Invalid docker-compose.yml configuration" $RED
    exit 1
fi
print_message "✅ docker-compose.yml is valid" $GREEN

# Clean build option
if [ "$CLEAN_BUILD" = true ]; then
    print_message "🧹 Cleaning existing images..." $YELLOW
    docker-compose down --rmi all --volumes --remove-orphans 2>/dev/null || true
    print_message "✅ Clean build completed" $GREEN
fi

# Check if images already exist
if [ "$FORCE_REBUILD" = false ] && [ "$CLEAN_BUILD" = false ]; then
    print_message "Checking for existing images..." $BLUE
    if docker images | grep -q "confluentinc/cp-kafka:7.4.0" && \
       docker images | grep -q "confluentinc/cp-zookeeper:7.4.0" && \
       docker images | grep -q "provectuslabs/kafka-ui:latest"; then
        print_message "✅ All required images already exist" $GREEN
        print_message "💡 Use --force to rebuild or --clean for fresh build" $YELLOW
    else
        FORCE_REBUILD=true
    fi
fi

# Pull/rebuild images
if [ "$FORCE_REBUILD" = true ]; then
    print_message "📥 Pulling Docker images..." $BLUE
    print_message "  • Kafka 7.4.0" $NC
    print_message "  • Zookeeper 7.4.0" $NC
    print_message "  • Kafka UI (latest)" $NC
    
    docker-compose pull
    
    print_message "✅ All images pulled successfully" $GREEN
fi

# Create data directories with proper permissions
print_message "📁 Setting up data directories..." $BLUE

# Create kafka_data directory
if [ ! -d "./kafka_data" ]; then
    mkdir -p ./kafka_data
    print_message "✅ Created kafka_data directory" $GREEN
else
    print_message "✅ kafka_data directory exists" $GREEN
fi

# Create zookeeper_data directory
if [ ! -d "./zookeeper_data" ]; then
    mkdir -p ./zookeeper_data
    print_message "✅ Created zookeeper_data directory" $GREEN
else
    print_message "✅ zookeeper_data directory exists" $GREEN
fi

# Set proper permissions (if on Unix-like system)
if [[ "$OSTYPE" != "msys" && "$OSTYPE" != "win32" ]]; then
    chmod 755 ./kafka_data ./zookeeper_data 2>/dev/null || true
fi

# Validate network availability
print_message "🌐 Checking network configuration..." $BLUE
if netstat -tuln 2>/dev/null | grep -q ":2181\|:8080\|:9092\|:9093"; then
    print_message "⚠️  Warning: Some required ports may be in use" $YELLOW
    netstat -tuln 2>/dev/null | grep -E ":2181|:8080|:9092|:9093" || true
else
    print_message "✅ Required ports are available" $GREEN
fi

# Show image information
print_message "📊 Image Information:" $BLUE
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}" | \
    grep -E "(confluentinc|provectuslabs)" || print_message "No Kafka images found" $YELLOW

print_message "\n🎉 Build completed successfully!" $GREEN

# Ask if user wants to start services
print_message "\n🚀 Starting services automatically..." $BLUE
print_message "Starting Kafka environment..." $YELLOW

# Start services
docker-compose up -d

# Wait for services to be healthy (reuse the health check function from start_kafka.sh)
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

# Open Kafka UI in browser (only on macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    print_message "\nOpening Kafka UI in browser..." $BLUE
    sleep 2
    open http://localhost:8080
fi

print_message "\n✅ Build and start completed successfully!" $GREEN
print_message "📋 Management Commands:" $BLUE
print_message "  • ./pause_kafka.sh        - Pause services (quick stop)" $NC
print_message "  • ./stop_kafka.sh         - Complete shutdown" $NC
print_message "  • ./monitor.sh status     - Check service health" $NC
print_message "  • ./list_topics.sh        - List topics" $NC
print_message "  • ./create_topic.sh <name> - Create new topic" $NC

print_message "\n💡 Build options used:" $YELLOW
if [ "$CLEAN_BUILD" = true ]; then
    print_message "  • Clean build: Removed existing images" $NC
fi
if [ "$FORCE_REBUILD" = true ]; then
    print_message "  • Force rebuild: Pulled latest images" $NC
fi
if [ "$FORCE_REBUILD" = false ] && [ "$CLEAN_BUILD" = false ]; then
    print_message "  • Smart build: Used existing images" $NC
fi
