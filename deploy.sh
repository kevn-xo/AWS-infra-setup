#!/bin/bash
set -e

# ═══════════════════════════════════════════════════════════════
#   AWS INFRASTRUCTURE DEPLOYMENT SCRIPT
#   Author      : Rithish
#   Description : Automated provisioning of 5 EC2 instances
#   Instances   : CPU Monitor, Web Server, MySQL, IIS, RDP
# ═══════════════════════════════════════════════════════════════

LOG_FILE="deploy.log"
exec > >(tee -a $LOG_FILE) 2>&1
echo "---------------------------------------------------------------"
echo "  DEPLOYMENT STARTED : $(date '+%Y-%m-%d %H:%M:%S')"
echo "---------------------------------------------------------------"

# ── CONFIGURATION ──────────────────────────────────────────────
KEY_NAME="my-project-key"
INSTANCE_TYPE_LINUX="t3.micro"
INSTANCE_TYPE_WINDOWS="t3.micro"
SUBNET_ID="subnet-0d81f8998843d260f"

# ── ENVIRONMENT DETECTION ──────────────────────────────────────
echo ""
echo "[1/7] Fetching AWS environment details..."

VPC_ID=$(aws ec2 describe-vpcs \
  --filters "Name=isDefault,Values=true" \
  --query "Vpcs[0].VpcId" --output text)

LINUX_AMI=$(aws ec2 describe-images --owners amazon \
  --filters "Name=name,Values=al2023-ami-2023*" \
  "Name=architecture,Values=x86_64" \
  "Name=state,Values=available" \
  --query "sort_by(Images, &CreationDate)[-1].ImageId" \
  --output text)

WINDOWS_AMI=$(aws ec2 describe-images --owners amazon \
  --filters "Name=name,Values=Windows_Server-2022-English-Full-Base*" \
  "Name=state,Values=available" \
  --query "sort_by(Images, &CreationDate)[-1].ImageId" \
  --output text)

LINUX_SG=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=linux-instances-sg" \
  --query "SecurityGroups[0].GroupId" --output text)

WINDOWS_SG=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=windows-instances-sg" \
  --query "SecurityGroups[0].GroupId" --output text)

echo "  VPC ID       : $VPC_ID"
echo "  Subnet ID    : $SUBNET_ID"
echo "  Linux AMI    : $LINUX_AMI"
echo "  Windows AMI  : $WINDOWS_AMI"
echo "  Linux SG     : $LINUX_SG"
echo "  Windows SG   : $WINDOWS_SG"

# ── INSTANCE PROVISIONING ──────────────────────────────────────
echo ""
echo "[2/7] Provisioning Instance 1 : CPU Monitor (Amazon Linux 2023)..."
CPU_INSTANCE=$(aws ec2 run-instances \
  --image-id $LINUX_AMI \
  --instance-type $INSTANCE_TYPE_LINUX \
  --key-name $KEY_NAME \
  --security-group-ids $LINUX_SG \
  --subnet-id $SUBNET_ID \
  --associate-public-ip-address \
  --user-data file://scripts/userdata_cpu_monitor.sh \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=CPU-Monitor}]' \
  --query 'Instances[0].InstanceId' --output text)
echo "  Instance ID  : $CPU_INSTANCE"

echo ""
echo "[3/7] Provisioning Instance 2 : Web Server (Amazon Linux 2023)..."
WEB_INSTANCE=$(aws ec2 run-instances \
  --image-id $LINUX_AMI \
  --instance-type $INSTANCE_TYPE_LINUX \
  --key-name $KEY_NAME \
  --security-group-ids $LINUX_SG \
  --subnet-id $SUBNET_ID \
  --associate-public-ip-address \
  --user-data file://scripts/userdata_webserver.sh \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Web-Server}]' \
  --query 'Instances[0].InstanceId' --output text)
echo "  Instance ID  : $WEB_INSTANCE"

echo ""
echo "[4/7] Provisioning Instance 3 : MySQL Server (Amazon Linux 2023)..."
MYSQL_INSTANCE=$(aws ec2 run-instances \
  --image-id $LINUX_AMI \
  --instance-type $INSTANCE_TYPE_LINUX \
  --key-name $KEY_NAME \
  --security-group-ids $LINUX_SG \
  --subnet-id $SUBNET_ID \
  --associate-public-ip-address \
  --user-data file://scripts/userdata_mysql.sh \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=MySQL-Server}]' \
  --query 'Instances[0].InstanceId' --output text)
echo "  Instance ID  : $MYSQL_INSTANCE"

echo ""
echo "[5/7] Provisioning Instance 4 : IIS Server (Windows Server 2022)..."
IIS_INSTANCE=$(aws ec2 run-instances \
  --image-id $WINDOWS_AMI \
  --instance-type $INSTANCE_TYPE_WINDOWS \
  --key-name $KEY_NAME \
  --security-group-ids $WINDOWS_SG \
  --subnet-id $SUBNET_ID \
  --associate-public-ip-address \
  --user-data file://scripts/userdata_iis.ps1 \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=IIS-Server}]' \
  --query 'Instances[0].InstanceId' --output text)
echo "  Instance ID  : $IIS_INSTANCE"

echo ""
echo "[6/7] Provisioning Instance 5 : RDP Server (Windows Server 2022)..."
RDP_INSTANCE=$(aws ec2 run-instances \
  --image-id $WINDOWS_AMI \
  --instance-type $INSTANCE_TYPE_WINDOWS \
  --key-name $KEY_NAME \
  --security-group-ids $WINDOWS_SG \
  --subnet-id $SUBNET_ID \
  --associate-public-ip-address \
  --user-data file://scripts/userdata_rdp.ps1 \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=RDP-Server}]' \
  --query 'Instances[0].InstanceId' --output text)
echo "  Instance ID  : $RDP_INSTANCE"

# ── WAIT FOR IPs ───────────────────────────────────────────────
echo ""
echo "[7/7] Waiting for public IPs to be assigned (30 seconds)..."
sleep 30

CPU_IP=$(aws ec2 describe-instances --instance-ids $CPU_INSTANCE \
  --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
WEB_IP=$(aws ec2 describe-instances --instance-ids $WEB_INSTANCE \
  --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
MYSQL_IP=$(aws ec2 describe-instances --instance-ids $MYSQL_INSTANCE \
  --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
IIS_IP=$(aws ec2 describe-instances --instance-ids $IIS_INSTANCE \
  --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
RDP_IP=$(aws ec2 describe-instances --instance-ids $RDP_INSTANCE \
  --query "Reservations[0].Instances[0].PublicIpAddress" --output text)

# ── SAVE INSTANCE IDs ──────────────────────────────────────────
cat > instance_ids.txt << EOF
CPU_MONITOR=$CPU_INSTANCE
WEB_SERVER=$WEB_INSTANCE
MYSQL_SERVER=$MYSQL_INSTANCE
IIS_SERVER=$IIS_INSTANCE
RDP_SERVER=$RDP_INSTANCE
EOF

# ── DEPLOYMENT SUMMARY ─────────────────────────────────────────
echo ""
echo "==============================================================="
echo "  DEPLOYMENT COMPLETE : $(date '+%Y-%m-%d %H:%M:%S')"
echo "==============================================================="
echo ""
echo "  INSTANCE SUMMARY"
echo "  ----------------"
printf "  %-20s %-22s %-18s\n" "NAME" "INSTANCE ID" "PUBLIC IP"
printf "  %-20s %-22s %-18s\n" "----" "-----------" "---------"
printf "  %-20s %-22s %-18s\n" "CPU-Monitor"  "$CPU_INSTANCE"   "$CPU_IP"
printf "  %-20s %-22s %-18s\n" "Web-Server"   "$WEB_INSTANCE"   "$WEB_IP"
printf "  %-20s %-22s %-18s\n" "MySQL-Server" "$MYSQL_INSTANCE" "$MYSQL_IP"
printf "  %-20s %-22s %-18s\n" "IIS-Server"   "$IIS_INSTANCE"   "$IIS_IP"
printf "  %-20s %-22s %-18s\n" "RDP-Server"   "$RDP_INSTANCE"   "$RDP_IP"
echo ""
echo "  CONNECTION DETAILS"
echo "  ------------------"
echo "  CPU Monitor  : ssh -i my-project-key.pem ec2-user@$CPU_IP"
echo "  Web Server   : http://$WEB_IP"
echo "  MySQL Server : ssh -i my-project-key.pem ec2-user@$MYSQL_IP"
echo "  IIS Server   : http://$IIS_IP  (ready in ~10 mins)"
echo "  RDP Server   : $RDP_IP  (password available in ~15 mins)"
echo ""
echo "  NOTES"
echo "  -----"
echo "  - Linux instances are ready in approximately 2-3 minutes"
echo "  - Windows instances (IIS, RDP) take 10-15 minutes to initialize"
echo "  - Retrieve RDP password using:"
echo "    aws ec2 get-password-data --instance-id $RDP_INSTANCE \\"
echo "    --priv-launch-key ~/aws-infra-setup/my-project-key.pem \\"
echo "    --query 'PasswordData' --output text"
echo "  - Deployment log saved to: deploy.log"
echo ""
echo "==============================================================="
