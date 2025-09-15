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
    print_message "Kafka Docker Setup - Stop Script" $BLUE
    print_message "Usage: $0 [options]" $YELLOW
    print_message "Options:" $NC
    print_message "  --remove-data, -r    Stop and remove all data permanently" $NC
    print_message "  --force, -f          Force stop and remove containers, keep data" $NC
    print_message "  --help, -h           Show this help message" $NC
    print_message "" $NC
    print_message "This script provides complete shutdown functionality:" $BLUE
    print_message "  • Default: Stop services but preserve all data" $NC
    print_message "  • Force: Remove containers but keep data volumes" $NC
    print_message "  • Remove-data: Complete cleanup including all data" $NC
    print_message "" $NC
    print_message "For quick pause/resume, use './pause_kafka.sh'" $YELLOW
}

print_message "🛑 Stopping Kafka Docker Setup..." $PURPLE

# Check the command line argument
if [ "$1" = "--remove-data" ] || [ "$1" = "-r" ]; then
    print_message "⚠️  WARNING: This will remove all Kafka data permanently!" $RED
    print_message "Press Ctrl+C within 5 seconds to cancel..." $YELLOW
    sleep 5
    
    print_message "Stopping services and removing all data..." $RED
    docker-compose down --volumes --remove-orphans
    print_message "Services stopped and all data removed." $GREEN
    
elif [ "$1" = "--force" ] || [ "$1" = "-f" ]; then
    print_message "Force stopping services (keeping data)..." $YELLOW
    docker-compose down --remove-orphans
    print_message "Services force stopped, data preserved." $GREEN
    
else
    # Default behavior - stop services but keep data
    print_message "Stopping services (data will be preserved)..." $YELLOW
    docker-compose stop
    print_message "Services stopped, data preserved." $GREEN
    print_message "💡 Use 'docker-compose start' to restart with existing data." $BLUE
fi

print_message "\n📋 Usage Summary:" $BLUE
print_message "  $0                 - Stop services, keep data" $NC
print_message "  $0 --force         - Stop and remove containers, keep data" $NC  
print_message "  $0 --remove-data   - Stop and remove everything including data" $NC

print_message "\n💡 Quick Commands:" $BLUE
print_message "  ./build_kafka.sh   - Build and start (complete setup)" $NC
print_message "  ./start_kafka.sh   - Start services only" $NC
print_message "  ./pause_kafka.sh   - Pause/resume services" $NC
print_message "  ./monitor.sh       - Check service status" $NC

# Show remaining containers/volumes if any
if docker ps -a --filter "name=kafka" --filter "name=zookeeper" --format "table {{.Names}}\t{{.Status}}" | grep -q "kafka\|zookeeper"; then
    print_message "\nRemaining containers:" $YELLOW
    docker ps -a --filter "name=kafka" --filter "name=zookeeper" --format "table {{.Names}}\t{{.Status}}"
fi
