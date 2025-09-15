#!/bin/zsh

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"

# Change to the script directory to ensure relative paths work
cd "$SCRIPT_DIR"

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

# Function to show service status
show_status() {
    print_message "🔍 Service Status:" $BLUE
    docker-compose ps
    echo
}

# Function to show resource usage
show_resources() {
    print_message "💾 Resource Usage:" $BLUE
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}" \
        kafka zookeeper kafka_ui 2>/dev/null || print_message "Some services may not be running" $YELLOW
    echo
}

# Function to show logs
show_logs() {
    local service=$1
    print_message "📋 Recent logs for $service:" $BLUE
    docker-compose logs --tail=20 "$service"
    echo
}

# Function to test connectivity
test_connectivity() {
    print_message "🔌 Testing Connectivity:" $BLUE
    
    # Test Zookeeper
    if nc -z localhost 2181 2>/dev/null; then
        print_message "✅ Zookeeper (2181): Connected" $GREEN
    else
        print_message "❌ Zookeeper (2181): Not reachable" $RED
    fi
    
    # Test Kafka
    if nc -z localhost 9092 2>/dev/null; then
        print_message "✅ Kafka (9092): Connected" $GREEN
    else
        print_message "❌ Kafka (9092): Not reachable" $RED
    fi
    
    # Test Kafka UI
    if nc -z localhost 8080 2>/dev/null; then
        print_message "✅ Kafka UI (8080): Connected" $GREEN
    else
        print_message "❌ Kafka UI (8080): Not reachable" $RED
    fi
    echo
}

# Function to show disk usage
show_disk_usage() {
    print_message "💽 Data Directory Usage:" $BLUE
    if [ -d "./kafka_data" ]; then
        du -sh ./kafka_data 2>/dev/null || echo "kafka_data: Unable to read"
    fi
    if [ -d "./zookeeper_data" ]; then
        du -sh ./zookeeper_data 2>/dev/null || echo "zookeeper_data: Unable to read"
    fi
    echo
}

# Main execution
case "${1:-status}" in
    "status"|"")
        show_status
        test_connectivity
        ;;
    "resources"|"res")
        show_resources
        ;;
    "logs")
        if [ -n "$2" ]; then
            show_logs "$2"
        else
            print_message "Available services: kafka, zookeeper, kafka_ui" $YELLOW
            print_message "Usage: $0 logs <service-name>" $BLUE
        fi
        ;;
    "disk")
        show_disk_usage
        ;;
    "all")
        show_status
        test_connectivity
        show_resources
        show_disk_usage
        ;;
    "help"|"-h"|"--help")
        print_message "Kafka Docker Setup Monitor" $BLUE
        print_message "Usage: $0 [command]" $YELLOW
        print_message "Commands:" $NC
        print_message "  status (default) - Show service status and connectivity" $NC
        print_message "  resources        - Show CPU and memory usage" $NC
        print_message "  logs <service>   - Show recent logs for a service" $NC
        print_message "  disk             - Show data directory disk usage" $NC
        print_message "  all              - Show all monitoring information" $NC
        ;;
    *)
        print_message "Unknown command: $1" $RED
        print_message "Use '$0 help' for usage information" $BLUE
        exit 1
        ;;
esac
