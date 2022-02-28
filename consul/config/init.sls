{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import consul as c %}
{%- from tplroot ~ '/macros.jinja' import format_kwargs %}
{%- set conf_dir = salt['file.dirname'](c['params']['config-file']) %}

{%- if c.install %}
  {#- Manage Consul configuration #}
include:
  - {{ tplroot }}.install
  - {{ tplroot }}.service
  - {{ tplroot }}.config.tls

  {#- Create parameters / environment file #}
consul_config_env_file:
  file.managed:
    - name: {{ c.config.env_file }}
    - source: salt://{{ tplroot }}/files/env_params.jinja
    - template: jinja
    - context:
        tplroot: {{ tplroot }}
        params: {{ c.params|tojson }}
    - watch_in:
      - service: consul_service_{{ c.service.status }}

  {#- Create data dir #}
consul_config_directory:
  file.directory:
    - name: {{ conf_dir }}
    - user: {{ c.user }}
    - group: {{ c.group }}
    - dir_mode: 755

  {#- Put config file in place #}
consul_config_file:
  file.managed:
    - name: {{ c['params']['config-file'] }}
    - source: salt://{{ tplroot }}/files/{{ c.config.source }}
    - user: {{ c.user }}
    - group: {{ c.group }}
    - mode: 640
    - template: jinja
    - context:
        tplroot: {{ tplroot }}
    {#- By default don't show changes to don't reveal tokens. #}
    - show_changes: {{ c.config.show_changes }}
    - require:
        - file: consul_config_directory
        - sls: {{ tplroot }}.config.tls
    - watch_in:
      - service: consul_service_{{ c.service.status }}

  {#- Create data dir #}
consul_config_data_directory:
  file.directory:
    - name: {{ c.config.data.data_dir }}
    - user: {{ c.user }}
    - group: {{ c.group }}
    - dir_mode: 750
    - makedirs: True
    - require_in:
      - service: consul_service_{{ c.service.status }}

{#- Consul is not selected for installation #}
{%- else %}
consul_config_install_notice:
  test.show_notification:
    - name: consul_config_install_notice
    - text: |
        Consul is not selected for installation, current value
        for 'consul:install': {{ c.install|string|lower }}, if you want to install Consul
        you need to set it to 'true'.

{%- endif %}
