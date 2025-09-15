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
    print_message "Kafka Docker Setup - Pause Script" $BLUE
    print_message "Usage: $0 [options]" $YELLOW
    print_message "Options:" $NC
    print_message "  --status, -s     Show pause/resume status" $NC
    print_message "  --help, -h       Show this help message" $NC
    print_message "" $NC
    print_message "This script provides quick pause functionality:" $BLUE
    print_message "  • Pause: Stops containers but preserves all data and state" $NC
    print_message "  • Status: Shows current pause/resume state" $NC
    print_message "" $NC
    print_message "Use this for temporary stops (lunch break, meetings, etc.)" $YELLOW
    print_message "To resume paused services, use './resume_kafka.sh'" $YELLOW
    print_message "For permanent shutdown, use './stop_kafka.sh'" $YELLOW
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

# Function to pause services
pause_services() {
    print_message "⏸️  Pausing Kafka services..." $PURPLE
    
    if ! check_services_running; then
        print_message "ℹ️  Services are not currently running" $BLUE
        return 0
    fi
    
    print_message "Stopping containers (preserving data and state)..." $YELLOW
    docker-compose stop
    
    print_message "✅ Services paused successfully!" $GREEN
    print_message "💾 All data and state preserved" $BLUE
    print_message "🔄 Use './resume_kafka.sh' to quickly restart" $YELLOW
}


# Function to show status
show_status() {
    print_message "📊 Kafka Services Status" $BLUE
    
    if check_services_running; then
        print_message "🟢 Status: RUNNING" $GREEN
        print_message "💡 Use './pause_kafka.sh' to pause services" $YELLOW
    elif check_services_paused; then
        print_message "🟡 Status: PAUSED" $YELLOW
        print_message "💡 Use './resume_kafka.sh' to resume services" $YELLOW
    else
        print_message "🔴 Status: STOPPED" $RED
        print_message "💡 Use './start_kafka.sh' to start services" $YELLOW
    fi
    
    print_message "\nContainer Details:" $BLUE
    docker-compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
    
    # Show data preservation status
    print_message "\n💾 Data Status:" $BLUE
    if [ -d "./kafka_data" ] && [ -d "./zookeeper_data" ]; then
        print_message "✅ Data directories exist and preserved" $GREEN
    else
        print_message "⚠️  Data directories missing" $YELLOW
    fi
}

# Parse command line arguments
case "${1:-pause}" in
    "pause"|"")
        pause_services
        ;;
    "status"|"--status"|"-s")
        show_status
        ;;
    "help"|"--help"|"-h")
        show_usage
        ;;
    *)
        print_message "Unknown option: $1" $RED
        show_usage
        exit 1
        ;;
esac

print_message "\n💡 Quick Commands:" $BLUE
print_message "  $0              - Pause services" $NC
print_message "  $0 --status     - Show status" $NC
print_message "  ./resume_kafka.sh - Resume services" $NC
print_message "  ./start_kafka.sh - Fresh start" $NC
print_message "  ./stop_kafka.sh  - Complete shutdown" $NC
