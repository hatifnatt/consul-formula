{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import consul as c %}

{#- Stop and disable service #}
consul_service_clean_dead:
  service.dead:
    - name: {{ c.service.name }}

consul_service_clean_disabled:
  service.disabled:
    - name: {{ c.service.name }}

{#- Install systemd service file #}
{%- if grains.init == 'systemd' %}

consul_service_clean_systemd_unit:
  file.absent:
    - name: {{ salt['file.join'](c.service.systemd.unit_dir,c.service.name ~ '.service') }}
    - watch_in:
      - module: consul_service_clean_reload_systemd

  {%- if c.use_upstream in ('binary', 'archive') %}
consul_service_clean_leftover_systemd_unit:
  file.absent:
    - name: {{ salt['file.join']('/usr/lib/systemd/system',c.service.name ~ '.service') }}
    - watch_in:
      - module: consul_service_clean_reload_systemd
  {%- endif %}

  {#- Reload systemd after unit file is removed, like `systemctl daemon-reload` #}
consul_service_clean_reload_systemd:
  module.wait:
  {#- Workaround for deprecated `module.run` syntax, subject to change in Salt 3005 #}
  {%- if 'module.run' in salt['config.get']('use_superseded', [])
      or grains['saltversioninfo'] >= [3005] %}
    - service.systemctl_reload: {}
  {%- else %}
    - name: service.systemctl_reload
  {%- endif %}

{%- else %}
consul_service_clean_warning:
  test.configurable_test_state:
    - name: consul_service_clean
    - changes: false
    - result: false
    - comment: |
        Your OS init system is {{ grains.init }}, currently only systemd init system is supported.
        Service for Consul is not altered (not removed).

{%- endif %}
