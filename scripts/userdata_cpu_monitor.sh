#!/bin/bash
yum update -y

# Create comprehensive monitoring script
cat > /usr/local/bin/system_monitor.sh << 'MONITOR'
#!/bin/bash
LOG_FILE="/var/log/system_monitor.log"

echo "======================================================" >> $LOG_FILE
echo "  SYSTEM MONITOR STARTED : $(date '+%Y-%m-%d %H:%M:%S')" >> $LOG_FILE
echo "  Hostname : $(hostname)" >> $LOG_FILE
echo "======================================================" >> $LOG_FILE

while true; do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

    # CPU Usage
    CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')

    # Memory Usage
    MEM_TOTAL=$(free -m | awk '/Mem:/{print $2}')
    MEM_USED=$(free -m | awk '/Mem:/{print $3}')
    MEM_PCT=$(awk "BEGIN {printf \"%.1f\", ($MEM_USED/$MEM_TOTAL)*100}")

    # Disk Usage
    DISK_USED=$(df -h / | awk 'NR==2{print $3}')
    DISK_TOTAL=$(df -h / | awk 'NR==2{print $2}')
    DISK_PCT=$(df -h / | awk 'NR==2{print $5}')

    # Network Stats
    NET_RX=$(cat /proc/net/dev | grep eth0 | awk '{print $2}')
    NET_TX=$(cat /proc/net/dev | grep eth0 | awk '{print $10}')

    # Load Average
    LOAD=$(uptime | awk -F'load average:' '{print $2}' | xargs)

    # Running Processes
    PROCS=$(ps aux --no-headers | wc -l)

    # Write to log
    {
    echo "------------------------------------------------------"
    echo "  TIMESTAMP    : $TIMESTAMP"
    echo "  CPU USAGE    : ${CPU}%"
    echo "  MEMORY       : ${MEM_USED}MB / ${MEM_TOTAL}MB (${MEM_PCT}%)"
    echo "  DISK         : ${DISK_USED} / ${DISK_TOTAL} (${DISK_PCT})"
    echo "  NETWORK RX   : ${NET_RX} bytes"
    echo "  NETWORK TX   : ${NET_TX} bytes"
    echo "  LOAD AVG     : ${LOAD}"
    echo "  PROCESSES    : ${PROCS}"
    echo "------------------------------------------------------"
    } >> $LOG_FILE

    sleep 5
done
MONITOR

chmod +x /usr/local/bin/system_monitor.sh

# Run as background service silently
nohup /usr/local/bin/system_monitor.sh > /dev/null 2>&1 &

# Store PID
echo $! > /var/run/system_monitor.pid

echo "System monitor started with PID $(cat /var/run/system_monitor.pid)"
