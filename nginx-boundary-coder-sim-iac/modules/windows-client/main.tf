#------------------------------------------------------------------------------
# Windows Client Module - Test Machine in Untrusted Zone
#
# This module deploys a Windows Server EC2 instance in the public subnet
# (untrusted zone) to simulate an external user accessing Coder through
# the NGINX boundary.
#
# The Windows machine has:
# - RDP access enabled for remote connection
# - Chrome browser pre-installed for testing
# - Desktop shortcut to Coder URL
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Data Sources
#------------------------------------------------------------------------------

# Latest Windows Server 2022 AMI
data "aws_ami" "windows" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

#------------------------------------------------------------------------------
# Security Group - RDP Access
# Allows RDP from specified CIDRs and all outbound traffic
#------------------------------------------------------------------------------

resource "aws_security_group" "windows" {
  name        = "${var.environment}-windows-client-sg"
  description = "Security group for Windows test client"
  vpc_id      = var.vpc_id

  # RDP access
  ingress {
    description = "RDP from allowed CIDRs"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = var.allowed_rdp_cidrs
  }

  # All outbound traffic (for accessing Coder)
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-windows-client-sg"
    Zone = "untrusted"
  }
}

#------------------------------------------------------------------------------
# Random Password for Administrator
#------------------------------------------------------------------------------

resource "random_password" "admin" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
}

#------------------------------------------------------------------------------
# Windows EC2 Instance
#------------------------------------------------------------------------------

resource "aws_instance" "windows" {
  ami           = data.aws_ami.windows.id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id

  vpc_security_group_ids      = [aws_security_group.windows.id]
  associate_public_ip_address = true

  # User data script to configure Windows
  user_data = base64encode(<<-EOF
    <powershell>
    # Set Administrator password
    $Password = ConvertTo-SecureString "${random_password.admin.result}" -AsPlainText -Force
    Set-LocalUser -Name "Administrator" -Password $Password
    
    # Enable RDP
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
    
    # Disable IE Enhanced Security Configuration (makes browsing painful)
    $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0
    Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0
    
    # Install Chocolatey package manager
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    
    # Refresh environment for choco
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    # Install Chrome browser
    choco install googlechrome -y --no-progress
    
    # Install VS Code (optional but useful for testing)
    choco install vscode -y --no-progress
    
    # Create desktop shortcut to Coder
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut("C:\Users\Public\Desktop\Coder.url")
    $Shortcut.TargetPath = "${var.coder_url}"
    $Shortcut.Save()
    
    # Create instructions file on desktop
    @"
    =====================================================
    NGINX Boundary + Coder Simulation Test Client
    =====================================================
    
    1. Open Chrome (NOT Internet Explorer)
    2. Navigate to: ${var.coder_url}
    3. Accept the self-signed certificate warning
    4. Create an admin account on first access
    5. Create a workspace using the "vite-workspace" template
    6. Once workspace starts, click the Vite app icon
    7. Verify the page loads via subdomain routing
    
    Expected URL pattern for Vite app:
    https://5173-<workspace>-<user>.${replace(var.coder_url, "https://", "")}
    
    =====================================================
    "@ | Out-File "C:\Users\Public\Desktop\README.txt"
    
    </powershell>
  EOF
  )

  root_block_device {
    volume_size = 50
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name = "${var.environment}-windows-client"
    Zone = "untrusted"
    Role = "test-client"
  }
}
