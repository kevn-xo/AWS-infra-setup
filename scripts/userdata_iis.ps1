<powershell>
# Wait for system to be ready
Start-Sleep -Seconds 30

# Install IIS with retry
$retries = 3
for ($i = 1; $i -le $retries; $i++) {
    try {
        Install-WindowsFeature -Name Web-Server -IncludeManagementTools -ErrorAction Stop
        break
    } catch {
        Start-Sleep -Seconds 30
    }
}

# Create HTML page
Set-Content -Path "C:\inetpub\wwwroot\index.html" -Value "<html><body><h1>Hello from IIS on AWS!</h1></body></html>"

# Start and enable IIS
Start-Service W3SVC
Set-Service W3SVC -StartupType Automatic
</powershell>
