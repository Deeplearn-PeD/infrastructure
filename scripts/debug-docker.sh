#!/bin/bash
# Docker Troubleshooting Script
# Run this on the Hetzner server to diagnose Docker issues

echo "=================================="
echo "Docker Troubleshooting"
echo "=================================="
echo ""

# Check if we're root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root"
    exit 1
fi

echo "1. System Information"
echo "--------------------"
uname -r
cat /etc/os-release | grep -E "^(NAME|VERSION)="
echo ""

echo "2. Docker Version"
echo "-----------------"
if command -v docker &> /dev/null; then
    docker --version
else
    echo "Docker not found"
fi
echo ""

echo "3. Docker Service Status"
echo "------------------------"
systemctl status docker --no-pager
echo ""

echo "4. Docker Service Logs (last 50 lines)"
echo "---------------------------------------"
journalctl -u docker.service -n 50 --no-pager
echo ""

echo "5. Check Docker Daemon Configuration"
echo "-------------------------------------"
if [ -f /etc/docker/daemon.json ]; then
    echo "Contents of /etc/docker/daemon.json:"
    cat /etc/docker/daemon.json
else
    echo "/etc/docker/daemon.json not found"
fi
echo ""

echo "6. Check Required Kernel Modules"
echo "---------------------------------"
lsmod | grep -E "overlay|bridge|nf_nat|ip_tables" || echo "Some modules missing"
echo ""

echo "7. Check AppArmor Status"
echo "------------------------"
if command -v aa-status &> /dev/null; then
    aa-status
else
    echo "AppArmor not installed or aa-status not available"
fi
echo ""

echo "8. Check System Resources"
echo "-------------------------"
free -h
df -h /
echo ""

echo "9. Check for Conflicting Packages"
echo "----------------------------------"
dpkg -l | grep -E "docker|containerd|runc" | awk '{print $2, $3}'
echo ""

echo "10. Try Manual Docker Start"
echo "---------------------------"
echo "Attempting to start Docker manually..."
if systemctl start docker; then
    echo "✓ Docker started successfully!"
    systemctl status docker --no-pager
else
    echo "✗ Docker failed to start"
    echo ""
    echo "Detailed error from journalctl:"
    journalctl -u docker.service -n 20 --no-pager
fi
echo ""

echo "11. Check Docker Socket"
echo "----------------------"
ls -la /var/run/docker.sock 2>/dev/null || echo "Docker socket not found"
echo ""

echo "12. Test Docker Command"
echo "----------------------"
if docker ps &> /dev/null; then
    echo "✓ Docker is working!"
    docker ps
else
    echo "✗ Docker command failed"
fi
echo ""

echo "=================================="
echo "Troubleshooting Complete"
echo "=================================="
