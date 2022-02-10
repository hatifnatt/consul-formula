{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import consul as c %}
{%- from tplroot ~ '/macros.jinja' import format_kwargs -%}

include:
  - {{ tplroot }}.service

{%- if c.tls.self_signed
    and 'key_file' in c.config
    and 'cert_file' in c.config
%}
  {#- Create self sifned TLS (SSL) certificate #}
consul_config_tls_prereq_packages:
  pkg.installed:
    - pkgs: {{ c.tls.packages|json }}

consul_config_tls_selfsigned_key:
  x509.private_key_managed:
    - name: {{ c.config.key_file }}
    - user: {{ c.user }}
    - group: {{ c.group }}
    - mode: 640
    - require:
      - pkg: consul_config_tls_prereq_packages

consul_config_tls_selfsigned_cert:
  x509.certificate_managed:
    - name: {{ c.config.cert_file }}
    - signing_private_key: {{ c.config.key_file }}
    {{- format_kwargs(c.tls.cert_params) }}
    - user: {{ c.user }}
    - group: {{ c.group }}
    - mode: 640
    - require:
      - x509: consul_config_tls_selfsigned_key
    - watch_in:
      - service: consul_service_{{ c.service.status }}

{%- elif not c.tls.self_signed
    and 'key_file' in c.config
    and 'cert_file' in c.config
%}

  {%- if c.tls.key_file_source.startswith('salt://') or c.tls.key_file_source.startswith('/') %}
    {%- set key_file_source = c.tls.key_file_source %}
  {%- else %}
    {%- set key_file_source = 'salt://' ~ tplroot ~ '/files/tls/' ~ c.tls.key_file_source %}
  {%- endif %}

  {%- if c.tls.cert_file_source.startswith('salt://') or c.tls.cert_file_source.startswith('/') %}
    {%- set cert_file_source = c.tls.cert_file_source %}
  {%- else %}
    {%- set cert_file_source = 'salt://' ~ tplroot ~ '/files/tls/' ~ c.tls.cert_file_source %}
  {%- endif %}

consul_config_tls_provided_key:
  file.managed:
    - name: {{ c.config.key_file }}
    - source: {{ key_file_source }}
    - user: {{ c.user }}
    - group: {{ c.group }}
    - mode: 640
    - watch_in:
      - service: consul_service_{{ c.service.status }}

consul_config_tls_provided_cert:
  file.managed:
    - name: {{ c.config.cert_file }}
    - source: {{ cert_file_source }}
    - user: {{ c.user }}
    - group: {{ c.group }}
    - mode: 640
    - watch_in:
      - service: consul_service_{{ c.service.status }}
{%- endif %}
