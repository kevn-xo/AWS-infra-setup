#!/bin/bash
LOG_FILE="/var/log/cpu_monitor.log"
echo "CPU Monitor started at $(date)" >> $LOG_FILE

while true; do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
    echo "[$TIMESTAMP] CPU Usage: ${CPU_USAGE}%" >> $LOG_FILE
    echo "[$TIMESTAMP] CPU Usage: ${CPU_USAGE}%"
    sleep 5
done
