#!/bin/bash
yum update -y
dnf install -y mariadb105-server
systemctl start mariadb
systemctl enable mariadb
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'Admin@1234';"
mysql -e "FLUSH PRIVILEGES;"
echo "mysql -u root -pAdmin@1234" >> /home/ec2-user/.bashrc
