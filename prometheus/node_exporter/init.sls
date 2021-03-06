# https://github.com/prometheus/node_exporter/releases
{% set version='0.15.2' %}

node_exporter_tarball_extracted:
  archive.extracted:
    - source: https://github.com/prometheus/node_exporter/releases/download/v{{ version }}/node_exporter-{{ version }}.linux-amd64.tar.gz
    - name: /tmp
    - archive_format: tar
    - source_hash: sha256=1ce667467e442d1f7fbfa7de29a8ffc3a7a0c84d24d7c695cc88b29e0752df37

/usr/local/bin/node_exporter:
  file.managed:
    - mode: 755
    - source: /tmp/node_exporter-{{ version }}.linux-amd64/node_exporter
    - require:
      - archive: node_exporter_tarball_extracted

/etc/systemd/system/node_exporter.service:
  file.managed:
    - mode: 644
    - source: salt://prometheus/node_exporter/node_exporter.service
    - template: jinja
    - context:
      host: {{ salt['pillar.get']('prometheus:node_exporter:host', '127.0.0.1') }}
      port: {{ salt['pillar.get']('prometheus:node_exporter:port', '9100') }}

node_exporter:
  service.running:
    - enable: True
    - watch:
      - file: /usr/local/bin/node_exporter
      - file: /etc/systemd/system/node_exporter.service
