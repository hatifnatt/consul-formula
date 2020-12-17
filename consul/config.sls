{% from "./map.jinja" import consul as c -%}
{% from "./macros.jinja" import format_kwargs -%}
{# Get 'current working directory' - path where current state file is located -#}
{% set tplroot = tplfile.split('/')[:-1] | join('/') -%}

include:
  - .install

{%- if c.tls.self_signed
    and 'key_file' in c.config
    and 'cert_file' in c.config
%}
{#- Create self sifned TLS (SSL) certificate #}
consul_tls_prereq_packages:
  pkg.installed:
    - pkgs: {{ c.tls.packages|json }}

consul_selfsigned_tls_key:
  x509.private_key_managed:
    - name: {{ c.config.key_file }}
    - user: {{ c.user }}
    - group: {{ c.group }}
    - mode: 640
    - require:
      - pkg: consul_tls_prereq_packages

consul_selfsigned_tls_cert:
  x509.certificate_managed:
    - name: {{ c.config.cert_file }}
    - signing_private_key: {{ c.config.key_file }}
    {{- format_kwargs(c.tls.cert_params) }}
    - user: {{ c.user }}
    - group: {{ c.group }}
    - mode: 640
    - require:
      - x509: consul_selfsigned_tls_key
    - watch_in:
      - service: consul_service

{%- elif not c.tls.self_signed
    and 'key_file' in c.config
    and 'cert_file' in c.config
%}

{%- if c.tls.key_file_source.startswith('salt://') or c.tls.key_file_source.startswith('/') %}
  {%- set key_file_source = c.tls.key_file_source %}
{%- else %}
  {%- set key_file_source = 'salt://' ~ tplroot ~ '/tls/' ~ c.tls.key_file_source %}
{%- endif %}

{%- if c.tls.cert_file_source.startswith('salt://') or c.tls.cert_file_source.startswith('/') %}
  {%- set cert_file_source = c.tls.cert_file_source %}
{%- else %}
  {%- set cert_file_source = 'salt://' ~ tplroot ~ '/tls/' ~ c.tls.cert_file_source %}
{%- endif %}

consul_provided_tls_key:
  file.managed:
    - name: {{ c.config.key_file }}
    - source: {{ key_file_source }}
    - user: {{ c.user }}
    - group: {{ c.group }}
    - mode: 640
    - watch_in:
      - service: consul_service

consul_provided_tls_cert:
  file.managed:
    - name: {{ c.config.cert_file }}
    - source: {{ cert_file_source }}
    - user: {{ c.user }}
    - group: {{ c.group }}
    - mode: 640
    - watch_in:
      - service: consul_service
{%- endif %}

{#- Create parameters / environment file #}
consul_env_file:
  file.managed:
    - name: {{ c.env_file }}
    - source: salt://{{ tplroot }}/files/env_params.jinja
    - template: jinja
    - context:
        params: {{ c.params|tojson }}
    - watch_in:
      - service: consul_service

{#- Put config file in place #}
consul_config:
  file.managed:
    - name: {{ c['params']['config-file'] }}
    - source: salt://{{ tplroot }}/files/{{ c.conf_source }}
    - user: {{ c.user }}
    - group: {{ c.group }}
    - mode: 640
    - template: jinja
    - context:
        tplroot: {{ tplroot }}
    {#- By default don't show changes to don't reveal tokens. #}
    - show_changes: {{ c.show_changes }}
    - require:
        - file: consul_conf_dir

{#- Create data dir #}
consul_data_dir:
  file.directory:
    - name: {{ c.config.data_dir }}
    - user: {{ c.user }}
    - group: {{ c.group }}
    - dir_mode: 750
    - makedirs: True
    - require_in:
      - service: consul_service

{#- Enable and start service #}
consul_service:
  service.running:
    - name: {{ c.service_name }}
    - enable: True
    - reload: {{ c.reload }}
    - watch:
      - file: consul_bin_symlink
      - file: consul_config
      - file: consul_systemd_unit
