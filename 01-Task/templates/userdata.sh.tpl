#!/bin/bash
set -e
exec > >(tee /var/log/user-data.log) 2>&1

echo "=== Updating packages ==="
apt-get update -y

echo "=== Installing Docker ==="
apt-get install -y ca-certificates curl gnupg
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

systemctl enable docker
systemctl start docker

echo "=== Writing Prometheus config ==="
mkdir -p /opt/monitoring
cat > /opt/monitoring/prometheus.yml << 'PROM_EOF'
${prometheus_config}
PROM_EOF

echo "=== Writing docker-compose.yml ==="
cat > /opt/monitoring/docker-compose.yml << 'COMPOSE_EOF'
${docker_compose}
COMPOSE_EOF

echo "=== Starting monitoring stack (prometheus, grafana, node_exporter) ==="
cd /opt/monitoring
docker compose up -d

echo "=== Bootstrap complete ==="
