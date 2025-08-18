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

print_message "Stopping Kafka Docker Setup..." $BLUE

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

print_message "\nUsage options:" $BLUE
print_message "  $0                 - Stop services, keep data" $NC
print_message "  $0 --force         - Stop and remove containers, keep data" $NC  
print_message "  $0 --remove-data   - Stop and remove everything including data" $NC

# Show remaining containers/volumes if any
if docker ps -a --filter "name=kafka" --filter "name=zookeeper" --format "table {{.Names}}\t{{.Status}}" | grep -q "kafka\|zookeeper"; then
    print_message "\nRemaining containers:" $YELLOW
    docker ps -a --filter "name=kafka" --filter "name=zookeeper" --format "table {{.Names}}\t{{.Status}}"
fi
