global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]

  - job_name: "monitoring_server_node_exporter"
    static_configs:
      - targets: ["${self_target}"]

  - job_name: "application_servers"
    static_configs:
      - targets: [
%{ for target in app_server_targets ~}
          "${target}",
%{ endfor ~}
        ]
