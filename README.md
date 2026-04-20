# AWS Infrastructure Setup

Automated provisioning of **5 configured EC2 instances** on AWS — triggered by a single command.

Built as part of an infrastructure automation project at Mphasis (Project Gensler), this script spins up a full mixed-OS environment across Amazon Linux 2023 and Windows Server 2022, each pre-configured with its intended service.

---

## Instances Provisioned

| # | Name | OS | Service |
|---|------|----|---------|
| 1 | **CPU Monitor** | Amazon Linux 2023 | System resource monitoring (CPU, RAM, Disk, Network) logged continuously |
| 2 | **Web Server** | Amazon Linux 2023 | Apache HTTPD with a custom HTML page |
| 3 | **MySQL Server** | Amazon Linux 2023 | MariaDB with root user pre-configured |
| 4 | **IIS Server** | Windows Server 2022 | IIS web server with a default HTML page |
| 5 | **RDP Server** | Windows Server 2022 | Remote Desktop access |

All instances use `t3.micro` and are assigned public IPs.

---

## Project Structure

```
aws-infra-setup/
├── deploy.sh                        # Main deployment script
├── instance_summary.txt             # Sample output reference
├── .gitignore
├── configs/
│   ├── cpu-monitor/
│   │   └── cpu_monitor.sh           # Standalone CPU monitor script
│   └── web/
│       └── index.html               # Web server landing page
│   └── mysql/
│       └── mysql_setup.sh           # MySQL setup reference
└── scripts/
    ├── userdata_cpu_monitor.sh      # EC2 user data — CPU Monitor
    ├── userdata_webserver.sh        # EC2 user data — Web Server
    ├── userdata_mysql.sh            # EC2 user data — MySQL Server
    ├── userdata_iis.ps1             # EC2 user data — IIS Server (PowerShell)
    └── userdata_rdp.ps1             # EC2 user data — RDP Server (PowerShell)
```

---

## Prerequisites

- AWS CLI configured (`aws configure`)
- An existing EC2 key pair named `my-project-key`
- Security groups created:
  - `linux-instances-sg` — allow SSH (22), HTTP (80)
  - `windows-instances-sg` — allow RDP (3389), HTTP (80)
- A valid subnet ID (update `SUBNET_ID` in `deploy.sh`)

---

## Usage

```bash
chmod +x deploy.sh
./deploy.sh
```

The script will:
1. Auto-detect your default VPC, latest AMIs, and security groups
2. Launch all 5 instances in parallel with pre-configured user data
3. Wait 30 seconds for IPs to be assigned
4. Print a full deployment summary with connection details
5. Save instance IDs to `instance_ids.txt` and logs to `deploy.log`

---

## Connecting to Instances

After deployment, the script outputs connection info:

```
CPU Monitor  →  ssh -i my-project-key.pem ec2-user@<IP>
Web Server   →  http://<IP>
MySQL Server →  ssh -i my-project-key.pem ec2-user@<IP>
IIS Server   →  http://<IP>           (ready in ~10 mins)
RDP Server   →  <IP>                  (password available in ~15 mins)
```

To retrieve the Windows RDP password:
```bash
aws ec2 get-password-data \
  --instance-id <RDP_INSTANCE_ID> \
  --priv-launch-key ~/aws-infra-setup/my-project-key.pem \
  --query 'PasswordData' --output text
```

---

## Timings

| Instance Type | Ready In |
|---------------|----------|
| Linux (CPU Monitor, Web, MySQL) | ~2–3 minutes |
| Windows (IIS, RDP) | ~10–15 minutes |

---

## Notes

- `.pem` key files and `instance_ids.txt` are git-ignored — never commit them
- Deployment logs are saved to `deploy.log`
- MySQL root password is set to `Admin@1234` — change this before any production use
- IIS serves a basic HTML page by default; swap out `C:\inetpub\wwwroot\index.html` to customize
