#!/bin/zsh

set -e

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

# Function to show usage
show_usage() {
    print_message "Usage: $0 <topic-name> [partitions] [replication-factor]" $BLUE
    print_message "Examples:" $YELLOW
    print_message "  $0 my-topic" $NC
    print_message "  $0 user-events 3" $NC
    print_message "  $0 orders 6 1" $NC
    exit 1
}

# Check if at least topic name is provided
if [ $# -lt 1 ]; then
    print_message "ERROR: Topic name is required" $RED
    show_usage
fi

TOPIC_NAME=$1
PARTITIONS=${2:-1}
REPLICATION_FACTOR=${3:-1}

# Check if Kafka container is running
if ! docker ps | grep -q "kafka.*Up"; then
    print_message "ERROR: Kafka container is not running. Please start it first with ./start_kafka.sh" $RED
    exit 1
fi

print_message "Creating Kafka topic..." $BLUE
print_message "Topic: $TOPIC_NAME" $NC
print_message "Partitions: $PARTITIONS" $NC
print_message "Replication Factor: $REPLICATION_FACTOR" $NC

# Create the topic
if docker exec kafka kafka-topics --create \
    --topic "$TOPIC_NAME" \
    --bootstrap-server localhost:9093 \
    --partitions "$PARTITIONS" \
    --replication-factor "$REPLICATION_FACTOR" \
    --if-not-exists; then
    
    print_message "✅ Topic '$TOPIC_NAME' created successfully!" $GREEN
    
    # Show topic details
    print_message "\nTopic details:" $BLUE
    docker exec kafka kafka-topics --describe \
        --topic "$TOPIC_NAME" \
        --bootstrap-server localhost:9093
else
    print_message "❌ Failed to create topic '$TOPIC_NAME'" $RED
    exit 1
fi
