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

# Check if Kafka container is running
if ! docker ps | grep -q "kafka.*Up"; then
    print_message "ERROR: Kafka container is not running. Please start it first with ./start_kafka.sh" $RED
    exit 1
fi

print_message "📋 Listing Kafka Topics..." $BLUE

# List all topics
TOPICS=$(docker exec kafka kafka-topics --list --bootstrap-server localhost:9093)

if [ -z "$TOPICS" ]; then
    print_message "No topics found." $YELLOW
else
    print_message "\nAvailable topics:" $GREEN
    echo "$TOPICS"
    
    # Show detailed information if requested
    if [ "$1" = "--details" ] || [ "$1" = "-d" ]; then
        print_message "\n📊 Topic Details:" $BLUE
        for topic in $TOPICS; do
            print_message "\n--- $topic ---" $YELLOW
            docker exec kafka kafka-topics --describe \
                --topic "$topic" \
                --bootstrap-server localhost:9093
        done
    fi
fi

print_message "\n💡 Use '$0 --details' to see detailed information about all topics." $BLUE
