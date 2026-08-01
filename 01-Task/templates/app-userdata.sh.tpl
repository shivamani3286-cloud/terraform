#!/bin/bash
set -e
exec > >(tee /var/log/user-data.log) 2>&1

echo "=== Installing Node Exporter ==="
useradd --no-create-home --shell /usr/sbin/nologin node_exporter || true

cd /tmp
NODE_EXPORTER_VERSION="1.8.2"
curl -sL "https://github.com/prometheus/node_exporter/releases/download/v$${NODE_EXPORTER_VERSION}/node_exporter-$${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz" -o node_exporter.tar.gz
tar xzf node_exporter.tar.gz
cp "node_exporter-$${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter" /usr/local/bin/
chown node_exporter:node_exporter /usr/local/bin/node_exporter

cat > /etc/systemd/system/node_exporter.service << 'EOF'
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable node_exporter
systemctl start node_exporter

echo "=== Node Exporter bootstrap complete ==="
