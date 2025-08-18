# Kafka Docker Setup

A complete, production-ready Apache Kafka setup using Docker Compose with Zookeeper and Kafka UI for local development and testing.

## 🚀 Quick Start

```bash
# Start all services
./start_kafka.sh

# Stop services (preserving data)
./stop_kafka.sh

# Create topics and start services
./start_kafka.sh --create-topics
```

Access Kafka UI at: http://localhost:8080

## 📋 What's Included

-   **Apache Kafka 7.4.0** - Latest stable version with optimized configuration
-   **Apache Zookeeper 7.4.0** - Coordination service for Kafka
-   **Kafka UI** - Web interface for managing Kafka clusters
-   **Health Checks** - Proper service dependency management
-   **Utility Scripts** - Easy topic management and monitoring

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Kafka UI      │    │     Kafka       │    │   Zookeeper     │
│   Port: 8080    │◄───│  Ports: 9092/93 │◄───│   Port: 2181    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🔧 Configuration Details

### Kafka Configuration

-   **Broker Listeners**:
    -   External: `localhost:9092` (for host applications)
    -   Internal: `kafka:9093` (for container communication)
-   **JVM Settings**: Optimized with G1GC and 512MB heap
-   **Log Retention**: 7 days / 1GB per topic
-   **Auto Topic Creation**: Enabled for development

### Zookeeper Configuration

-   **Data Retention**: 3 snapshots, 24h cleanup interval
-   **Connection Limit**: 60 concurrent clients
-   **Health Monitoring**: Built-in connectivity checks

## 📁 File Structure

```
kafka-docker-setup/
├── docker-compose.yml      # Main service definitions
├── start_kafka.sh         # Start script with health checks
├── stop_kafka.sh          # Stop script with data protection
├── create_topic.sh        # Topic creation utility
├── list_topics.sh         # Topic listing utility
├── monitor.sh             # System monitoring
├── kafka_data/            # Kafka data persistence
├── zookeeper_data/        # Zookeeper data persistence
└── README.md              # This file
```

## 🛠️ Available Scripts

### Core Scripts

#### `./start_kafka.sh [options]`

Starts all Kafka services with proper health checks.

**Options:**

-   `--create-topics` or `-t`: Create example topics after startup

**Features:**

-   ✅ Health checks for all services
-   ✅ Colored output with progress indicators
-   ✅ Automatic browser opening (macOS)
-   ✅ Service status validation

#### `./stop_kafka.sh [options]`

Stops Kafka services with data protection.

**Options:**

-   (default): Stop services, keep data
-   `--force` or `-f`: Stop and remove containers, keep data
-   `--remove-data` or `-r`: Stop and remove everything including data

### Utility Scripts

#### `./create_topic.sh <name> [partitions] [replication-factor]`

Creates a new Kafka topic.

**Examples:**

```bash
./create_topic.sh my-topic
./create_topic.sh user-events 3
./create_topic.sh orders 6 1
```

#### `./list_topics.sh [--details]`

Lists all Kafka topics.

**Options:**

-   `--details` or `-d`: Show detailed topic information

#### `./monitor.sh [command]`

Monitors the Kafka setup.

**Commands:**

-   `status` (default): Service status and connectivity
-   `resources`: CPU and memory usage
-   `logs <service>`: Recent logs for a service
-   `disk`: Data directory usage
-   `all`: Complete monitoring overview

## 🔌 Connection Details

| Service   | External Port | Internal Address | Purpose        |
| --------- | ------------- | ---------------- | -------------- |
| Kafka     | 9092          | kafka:9093       | Message broker |
| Zookeeper | 2181          | zookeeper:2181   | Coordination   |
| Kafka UI  | 8080          | kafka_ui:8080    | Web interface  |

## 💻 Usage Examples

### Connect from Host Applications

```bash
# Producer example
echo "test message" | docker exec -i kafka kafka-console-producer \
  --bootstrap-server localhost:9092 --topic test-topic

# Consumer example
docker exec kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 --topic test-topic --from-beginning
```

### Connect from Other Containers

```yaml
# In your docker-compose.yml
services:
    your-app:
        environment:
            KAFKA_BOOTSTRAP_SERVERS: "kafka:9093"
        networks:
            - kafka-net

networks:
    kafka-net:
        external: true
        name: kafka-docker-setup_kafka-net
```

### Application Configuration

```properties
# For Spring Boot applications
spring.kafka.bootstrap-servers=localhost:9092
spring.kafka.consumer.group-id=my-consumer-group
```

## 🔍 Monitoring & Troubleshooting

### Check Service Health

```bash
./monitor.sh status
```

### View Logs

```bash
./monitor.sh logs kafka
./monitor.sh logs zookeeper
./monitor.sh logs kafka_ui
```

### Resource Usage

```bash
./monitor.sh resources
```

### Manual Docker Commands

```bash
# View all containers
docker-compose ps

# Follow logs
docker-compose logs -f kafka

# Access Kafka container
docker exec -it kafka bash
```

### Common Issues

#### Services won't start

```bash
# Check if ports are available
netstat -tulpn | grep -E ':(2181|8080|9092|9093)'

# Restart Docker
sudo systemctl restart docker  # Linux
# or restart Docker Desktop
```

#### Can't connect to Kafka

```bash
# Verify Kafka is listening
docker exec kafka kafka-broker-api-versions --bootstrap-server localhost:9093

# Check network connectivity
docker network ls | grep kafka
```

#### Data corruption

```bash
# Stop and clean (WARNING: deletes all data)
./stop_kafka.sh --remove-data
./start_kafka.sh
```

## 🛡️ Security Notes

This setup is configured for **development use only**. For production:

-   [ ] Enable SASL/SSL authentication
-   [ ] Configure proper network security
-   [ ] Set up monitoring and alerting
-   [ ] Implement backup strategies
-   [ ] Review log retention policies

## 🔄 Backup & Recovery

### Manual Backup

```bash
# Stop services
./stop_kafka.sh

# Backup data directories
tar -czf kafka-backup-$(date +%Y%m%d).tar.gz kafka_data/ zookeeper_data/

# Restart services
./start_kafka.sh
```

### Restore from Backup

```bash
# Stop and clean
./stop_kafka.sh --remove-data

# Extract backup
tar -xzf kafka-backup-YYYYMMDD.tar.gz

# Restart
./start_kafka.sh
```

## 📊 Performance Tuning

The setup includes optimized defaults:

-   **JVM Heap**: 512MB (adjust `KAFKA_HEAP_OPTS` for production)
-   **G1 Garbage Collector**: Better for Kafka workloads
-   **Log Segments**: 1GB chunks for optimal performance
-   **Retention**: 7 days / 1GB per topic

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Test your changes thoroughly
4. Submit a pull request

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

-   **Issues**: Report bugs or request features via GitHub issues
-   **Documentation**: Kafka official docs at https://kafka.apache.org/documentation/
-   **Community**: Confluent Community Forum

---

**Happy Kafka-ing! 🎉**
