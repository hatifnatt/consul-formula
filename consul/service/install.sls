{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import consul as c %}

{%- if c.install %}
  {#- Install systemd service file #}
  {%- if c.use_upstream in ('binary', 'archive') %}
    {%- if grains.init == 'systemd' %}
include:
  - {{ tplroot }}.service

consul_service_install_systemd_unit:
  file.managed:
    - name: {{ salt['file.join'](c.service.systemd.unit_dir,c.service.name ~ '.service') }}
    - source: salt://{{ tplroot }}/files/consul.service.jinja
    - user: {{ c.root_user }}
    - group: {{ c.root_group }}
    - mode: 644
    - template: jinja
    - context:
        tplroot: {{ tplroot }}
    - require_in:
      - sls: {{ tplroot }}.service
    - watch_in:
      - module: consul_service_install_reload_systemd

      {#- Reload systemd after new unit file added, like `systemctl daemon-reload` #}
consul_service_install_reload_systemd:
  module.wait:
      {#- Workaround for deprecated `module.run` syntax, subject to change in Salt 3005 #}
      {%- if 'module.run' in salt['config.get']('use_superseded', [])
      or grains['saltversioninfo'] >= [3005] %}
    - service.systemctl_reload: {}
      {%- else %}
    - name: service.systemctl_reload
      {%- endif %}
    - require_in:
      - sls: {{ tplroot }}.service

    {%- else %}
consul_service_install_warning:
  test.configurable_test_state:
    - name: consul_service_install
    - changes: false
    - result: false
    - comment: |
        Your OS init system is {{ grains.init }}, currently only systemd init system is supported.
        Service for Consul is not installed.

    {%- endif %}

  {#- Another installation method is selected #}
  {%- else %}
consul_service_install_method:
  test.show_notification:
    - name: consul_service_install_method
    - text: |
        Another installation method is selected. If you want to use binary
        installation method set 'consul:use_upstream' to 'binary' or 'archive'.
        Current value of consul:use_upstream: '{{ c.use_upstream }}'
  {%- endif %}

{#- Consul is not selected for installation #}
{%- else %}
consul_service_install_notice:
  test.show_notification:
    - name: consul_service_install
    - text: |
        Consul is not selected for installation, current value
        for 'consul:install': {{ c.install|string|lower }}, if you want to install Consul
        you need to set it to 'true'.

{%- endif %}
