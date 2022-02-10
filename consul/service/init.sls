{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import consul as c %}

{%- if c.install %}
  {#- Manage on boot service state in dedicated state to ensure watch trigger properly in service.running state #}
consul_service_{{ c.service.on_boot_state }}:
  service.{{ c.service.on_boot_state }}:
    - name: {{ c.service.name }}

consul_service_{{ c.service.status }}:
  service:
    - name: {{ c.service.name }}
    - {{ c.service.status }}
  {%- if c.service.status == 'running' %}
    - reload: {{ c.service.reload }}
  {%- endif %}
    - require:
        - service: consul_service_{{ c.service.on_boot_state }}
    - order: last

{#- Consul is not selected for installation #}
{%- else %}
consul_service_notice:
  test.show_notification:
    - name: consul_service_notice
    - text: |
        Consul is not selected for installation, current value
        for 'consul:install': {{ c.install|string|lower }}, if you want to install Consul
        you need to set it to 'true'.

{%- endif %}
