terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.11"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ---------------------------------------------------------------------------
# Render configs from templates. App server targets are pulled straight from
# the app instances Terraform just created - no manual IP entry needed.
# ---------------------------------------------------------------------------
locals {
  prometheus_config = templatefile("${path.module}/templates/prometheus.yml.tpl", {
    app_server_targets = [for instance in aws_instance.app : "${instance.private_ip}:9100"]
    self_target         = "localhost:9100"
  })

  docker_compose = templatefile("${path.module}/templates/docker-compose.yml.tpl", {
    grafana_admin_password = var.grafana_admin_password
  })

  monitoring_userdata = templatefile("${path.module}/templates/userdata.sh.tpl", {
    prometheus_config = local.prometheus_config
    docker_compose     = local.docker_compose
  })
}

# ---------------------------------------------------------------------------
# EC2 instance - monitoring server (Docker + Prometheus + Grafana + Node Exporter)
# ---------------------------------------------------------------------------
resource "aws_instance" "monitoring" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.generated.key_name
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.monitoring_sg.id]

  # Make sure app servers exist first, so their private IPs are already
  # known when we render prometheus.yml into this instance's user_data.
  depends_on = [aws_instance.app]

  user_data                   = local.monitoring_userdata
  user_data_replace_on_change = true

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "${var.project_name}-monitoring-server"
  }
}

# ---------------------------------------------------------------------------
# Give the instance time to finish bootstrapping (apt install + docker pulls)
# ---------------------------------------------------------------------------
resource "time_sleep" "wait_for_bootstrap" {
  depends_on      = [aws_instance.monitoring]
  create_duration = "90s"
}

# ---------------------------------------------------------------------------
# Verify Prometheus and Grafana are actually up and serving traffic
# ---------------------------------------------------------------------------
resource "null_resource" "verify_dashboards" {
  depends_on = [time_sleep.wait_for_bootstrap]

  triggers = {
    instance_id = aws_instance.monitoring.id
  }

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]
    command     = <<-EOT
      $ip = "${aws_instance.monitoring.public_ip}"

      Write-Host "Checking Prometheus at http://$ip:9090 ..."
      $promOk = $false
      for ($i = 1; $i -le 10; $i++) {
        try {
          $resp = Invoke-WebRequest -Uri "http://$ip:9090/-/healthy" -UseBasicParsing -TimeoutSec 5
          if ($resp.StatusCode -eq 200) {
            Write-Host "Prometheus is UP"
            $promOk = $true
            break
          }
        } catch {
          Write-Host "Prometheus not ready yet, retrying ($i/10)..."
        }
        Start-Sleep -Seconds 15
      }

      Write-Host "Checking Grafana at http://$ip:3000 ..."
      $grafOk = $false
      for ($i = 1; $i -le 10; $i++) {
        try {
          $resp = Invoke-WebRequest -Uri "http://$ip:3000/api/health" -UseBasicParsing -TimeoutSec 5
          if ($resp.StatusCode -eq 200) {
            Write-Host "Grafana is UP"
            $grafOk = $true
            break
          }
        } catch {
          Write-Host "Grafana not ready yet, retrying ($i/10)..."
        }
        Start-Sleep -Seconds 15
      }

      if ($promOk -and $grafOk) {
        Write-Host "SUCCESS: both dashboards are accessible."
      } else {
        Write-Host "WARNING: one or more dashboards did not respond in time. SSH in and check /var/log/user-data.log"
      }
    EOT
  }
}
