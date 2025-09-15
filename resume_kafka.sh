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
    print_message "Kafka Docker Setup - Resume Script" $BLUE
    print_message "Usage: $0 [options]" $YELLOW
    print_message "Options:" $NC
    print_message "  --help, -h       Show this help message" $NC
    print_message "" $NC
    print_message "This script quickly resumes paused Kafka services:" $BLUE
    print_message "  • Resumes paused containers" $NC
    print_message "  • Preserves all data and state" $NC
    print_message "  • Performs health checks" $NC
    print_message "  • Shows service status" $NC
    print_message "" $NC
    print_message "Use this after pausing services with './pause_kafka.sh'" $YELLOW
}

# Function to check if services are running
check_services_running() {
    if docker-compose ps | grep -q "Up"; then
        return 0  # Services are running
    else
        return 1  # Services are not running
    fi
}

# Function to check if services are paused (stopped but containers exist)
check_services_paused() {
    if docker-compose ps | grep -q "Exited" && ! docker-compose ps | grep -q "Up"; then
        return 0  # Services are paused
    else
        return 1  # Services are not paused
    fi
}

# Function to wait for service health
wait_for_service_health() {
    local service_name=$1
    local max_attempts=30
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
        
        if [ $((attempt % 5)) -eq 0 ]; then
            print_message "Still waiting for $service_name... (attempt $attempt/$max_attempts)" $YELLOW
        fi
        
        sleep 2
        attempt=$((attempt + 1))
    done
    
    print_message "WARNING: $service_name may not be fully ready yet" $YELLOW
    return 1
}

# Parse command line arguments
case "${1:-resume}" in
    "resume"|"")
        # Main resume functionality
        ;;
    "help"|"--help"|"-h")
        show_usage
        exit 0
        ;;
    *)
        print_message "Unknown option: $1" $RED
        show_usage
        exit 1
        ;;
esac

print_message "▶️  Resuming Kafka services..." $PURPLE

# Check if services are already running
if check_services_running; then
    print_message "ℹ️  Services are already running" $BLUE
    print_message "📊 Current Status:" $BLUE
    docker-compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
    exit 0
fi

# Check if services are paused
if ! check_services_paused; then
    print_message "⚠️  No paused services found." $YELLOW
    print_message "💡 Available options:" $BLUE
    print_message "  • ./start_kafka.sh - Start services fresh" $NC
    print_message "  • ./build_kafka.sh - Complete build and start" $NC
    print_message "  • ./pause_kafka.sh --status - Check current status" $NC
    exit 1
fi

# Resume services
print_message "Starting paused containers..." $YELLOW
docker-compose start

# Wait for services to be ready
print_message "Waiting for services to be ready..." $BLUE
sleep 5

# Wait for services to be healthy
wait_for_service_health "zookeeper"
wait_for_service_health "kafka"
wait_for_service_health "kafka_ui"

# Check final status
if check_services_running; then
    print_message "✅ Services resumed successfully!" $GREEN
    
    # Show service status
    print_message "\n📊 Service Status:" $BLUE
    docker-compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
    
    # Display connection information
    print_message "\n🔗 Access Points:" $BLUE
    print_message "  • Kafka UI: http://localhost:8080" $NC
    print_message "  • Kafka Broker: localhost:9092" $NC
    print_message "  • Zookeeper: localhost:2181" $NC
    
    print_message "\n💡 Quick Commands:" $BLUE
    print_message "  • ./pause_kafka.sh - Pause services again" $NC
    print_message "  • ./stop_kafka.sh - Complete shutdown" $NC
    print_message "  • ./monitor.sh status - Check health" $NC
    print_message "  • ./list_topics.sh - List topics" $NC
    
else
    print_message "❌ Failed to resume services properly." $RED
    print_message "🔄 Attempting automatic recovery with build_kafka.sh..." $YELLOW
    
    # Try to run build_kafka.sh automatically
    if [ -f "./build_kafka.sh" ]; then
        print_message "Running build_kafka.sh for automatic recovery..." $BLUE
        if ./build_kafka.sh; then
            print_message "✅ Automatic recovery successful!" $GREEN
            exit 0
        else
            print_message "❌ Automatic recovery failed." $RED
        fi
    else
        print_message "⚠️  build_kafka.sh not found in current directory" $YELLOW
    fi
    
    print_message "\n💡 Manual troubleshooting steps:" $YELLOW
    print_message "  • Check logs: docker-compose logs" $NC
    print_message "  • Restart fresh: ./start_kafka.sh" $NC
    print_message "  • Complete rebuild: ./build_kafka.sh --clean" $NC
    exit 1
fi

print_message "\n🎉 Kafka services are back online!" $GREEN
