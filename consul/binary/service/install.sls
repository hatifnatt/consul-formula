{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import consul as c %}

{#- Install systemd service file #}
{%- if grains.init == 'systemd' %}
consul_binary_service_install_systemd_unit:
  file.managed:
    - name: {{ salt['file.join'](c.systemd_unit_dir,c.service_name ~ '.service') }}
    - source: salt://{{ tplroot }}/files/consul.service.jinja
    - user: {{ c.root_user }}
    - group: {{ c.root_group }}
    - mode: 644
    - template: jinja
    - context:
        tplroot: {{ tplroot }}
    - watch_in:
      - module: consul_binary_service_install_reload_systemd

  {#- Reload systemd after new unit file added, like `systemctl daemon-reload` #}
consul_binary_service_install_reload_systemd:
  module.wait:
  {#- Workaround for deprecated `module.run` syntax, subject to change in Salt 3005 #}
  {%- if 'module.run' in salt['config.get']('use_superseded', [])
      or grains['saltversioninfo'] >= [3005] %}
    - service.systemctl_reload: {}
  {%- else %}
    - name: service.systemctl_reload
  {%- endif %}

{%- else %}
consul_binary_service_install_warning:
  test.configurable_test_state:
    - name: consul_binary_service_install
    - changes: false
    - result: false
    - comment: |
        Your OS init system is {{ grains.init }}, currently only systemd init system is supported.
        Service for Consul is not installed.

{%- endif %}
