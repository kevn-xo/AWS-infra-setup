#!/bin/bash
# Install MySQL
sudo dnf install -y mysql-server
sudo systemctl start mysqld
sudo systemctl enable mysqld

# Set root password
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'Admin@1234';"
sudo mysql -e "FLUSH PRIVILEGES;"

# Auto-launch MySQL CLI on SSH login for root user
echo "mysql -u root -pAdmin@1234" | sudo tee -a /root/.bashrc
echo "mysql -u root -pAdmin@1234" | sudo tee -a /home/ec2-user/.bashrc

echo "MySQL setup complete!"
