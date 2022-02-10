{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import consul as c %}
{%- from tplroot ~ '/macros.jinja' import format_kwargs -%}
{%- set conf_dir = salt['file.dirname'](c['params']['config-file']) -%}

include:
  - {{ tplroot }}.install
  - {{ tplroot }}.service
  - {{ slsdotpath }}.tls

{#- Create parameters / environment file #}
consul_env_file:
  file.managed:
    - name: {{ c.env_file }}
    - source: salt://{{ tplroot }}/files/env_params.jinja
    - template: jinja
    - context:
        params: {{ c.params|tojson }}
    - watch_in:
      - service: consul_service_{{ c.service.status }}

{#- Create data dir #}
consul_conf_dir:
  file.directory:
    - name: {{ conf_dir }}
    - user: {{ c.user }}
    - group: {{ c.group }}
    - dir_mode: 755

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
        - sls: {{ slsdotpath }}.tls
    - watch_in:
      - service: consul_service_{{ c.service.status }}

{#- Create data dir #}
consul_data_dir:
  file.directory:
    - name: {{ c.config.data_dir }}
    - user: {{ c.user }}
    - group: {{ c.group }}
    - dir_mode: 750
    - makedirs: True
    - require_in:
      - service: consul_service_{{ c.service.status }}