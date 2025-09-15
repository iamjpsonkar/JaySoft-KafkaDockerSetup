# Kafka Docker Setup - 4-Script Architecture

## 🎯 Script Overview

| Script | Purpose | Key Features |
|--------|---------|--------------|
| **build_kafka.sh** | Complete Setup | Builds images, starts services, health checks |
| **start_kafka.sh** | Quick Start | Starts services only (assumes images exist) |
| **pause_kafka.sh** | Temporary Stop | Pause services with data preservation |
| **kafka_resume.sh** | Quick Resume | Resume paused services with health checks |
| **stop_kafka.sh** | Complete Shutdown | Full stop with data management options |

## 🚀 Quick Start Workflow

### First Time Setup:
```bash
# From anywhere on your system:
bash /path/to/kafka-docker-setup/build_kafka.sh

# Or from the project directory:
./build_kafka.sh
```

### Daily Usage:
```bash
# From anywhere on your system:
bash /path/to/kafka-docker-setup/start_kafka.sh
bash /path/to/kafka-docker-setup/pause_kafka.sh
bash /path/to/kafka-docker-setup/kafka_resume.sh
bash /path/to/kafka-docker-setup/stop_kafka.sh

# Or from the project directory:
./start_kafka.sh
./pause_kafka.sh
./kafka_resume.sh
./stop_kafka.sh
```

## 📋 Script Details

### build_kafka.sh
- **Purpose**: Complete environment setup
- **Does**: Pulls images, creates directories, starts services, health checks
- **Options**: --force, --clean, --help
- **Use when**: First time setup, major updates

### start_kafka.sh  
- **Purpose**: Quick service startup
- **Does**: Starts services, health checks, displays status
- **Options**: --create-topics, --no-browser, --help
- **Use when**: Daily development, services already built

### pause_kafka.sh
- **Purpose**: Temporary service suspension
- **Does**: Pause services with state preservation
- **Options**: --status, --help
- **Use when**: Lunch breaks, meetings, quick stops

### kafka_resume.sh
- **Purpose**: Quick service resumption
- **Does**: Resume paused services with health checks
- **Options**: --help
- **Use when**: Resuming after pause, quick restart

### stop_kafka.sh
- **Purpose**: Complete shutdown
- **Does**: Stops services with data management
- **Options**: --remove-data, --force, --help
- **Use when**: End of day, cleanup, maintenance

## 🔧 Advanced Options

### Build Options:
```bash
./build_kafka.sh --clean    # Fresh build (removes existing images)
./build_kafka.sh --force    # Force rebuild even if images exist
```

### Start Options:
```bash
./start_kafka.sh --create-topics  # Create example topics
./start_kafka.sh --no-browser     # Don't open browser
```

### Stop Options:
```bash
./stop_kafka.sh --force       # Remove containers, keep data
./stop_kafka.sh --remove-data # Complete cleanup (WARNING: deletes data)
```

## 💡 Best Practices

1. **First time**: Use `./build_kafka.sh`
2. **Daily work**: Use `./start_kafka.sh`, `./pause_kafka.sh`, and `./kafka_resume.sh`
3. **End of day**: Use `./stop_kafka.sh`
4. **Cleanup**: Use `./stop_kafka.sh --remove-data` (careful!)

## 🎉 Benefits

- **Clear separation** of concerns
- **Flexible workflow** for different use cases  
- **Data safety** with multiple stop options
- **Quick operations** for daily development
- **Complete setup** for new environments
- **Run from anywhere** - no need to cd to project directory
- **Absolute path support** - works with full paths from any location
