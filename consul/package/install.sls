{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import consul as c %}
{%- set conf_dir = salt['file.dirname'](c['params']['config-file']) -%}

{%- if c.install %}
  {#- Install Consul from packages #}
  {%- if c.use_upstream in ('repo', 'package') %}
include:
  - {{ tplroot }}.repo
  - {{ tplroot }}.shell_completion.bash.install
  - {{ tplroot }}.backup_helper.install
  - {{ tplroot }}.service.install

    {#- Install packages required for further execution of 'package' installation method #}
    {%- if 'prereq_pkgs' in c.package and c.package.prereq_pkgs %}
consul_package_install_prerequisites:
  pkg.installed:
    - pkgs: {{ c.package.prereq_pkgs|tojson }}
    - require:
      - sls: {{ tplroot }}.repo
    - require_in:
      - pkg: consul_package_install
    {%- endif %}

    {%- if 'pkgs_extra' in c.package and c.package.pkgs_extra %}
consul_package_install_extra:
  pkg.installed:
    - pkgs: {{ c.package.pkgs_extra|tojson }}
    - require:
      - sls: {{ tplroot }}.repo
    - require_in:
      - pkg: consul_package_install
    {%- endif %}

consul_package_install:
  pkg.installed:
    - pkgs:
    {%- for pkg in c.package.pkgs %}
      - {{ pkg }}{% if c.version is defined and 'consul' in pkg %}: '{{ c.version }}'{% endif %}
    {%- endfor %}
    - hold: {{ c.package.hold }}
    - update_holds: {{ c.package.update_holds }}
    {%- if salt['grains.get']('os_family') == 'Debian' %}
    - install_recommends: {{ c.package.install_recommends }}
    {%- endif %}
    - watch_in:
      - service: consul_service_{{ c.service.status }}
    - require:
      - sls: {{ tplroot }}.repo
    - require_in:
      - sls: {{ tplroot }}.service.install

    {#- Create group and user #}
consul_package_install_group:
  group.present:
    - name: {{ c.group }}
    - system: True
    - require:
      - pkg: consul_package_install

consul_package_install_user:
  user.present:
    - name: {{ c.user }}
    - gid: {{ c.group }}
    - system: True
    - password: '*'
    - home: {{ conf_dir }}
    - createhome: False
    - shell: /usr/sbin/nologin
    - fullname: Consul daemon
    - require:
      - group: consul_package_install_group
    - require_in:
      - sls: {{ tplroot }}.backup_helper.install
      - sls: {{ slsdotpath }}.service.install

  {#- Another installation method is selected #}
  {%- else %}
consul_package_install_method:
  test.show_notification:
    - name: consul_package_install_method
    - text: |
        Another installation method is selected. If you want to use package
        installation method set 'consul:use_upstream' to 'package' or 'repo'.
        Current value of consul:use_upstream: '{{ c.use_upstream }}'
  {%- endif %}

{#- Consul is not selected for installation #}
{%- else %}
consul_package_install_notice:
  test.show_notification:
    - name: consul_package_install
    - text: |
        Consul is not selected for installation, current value
        for 'consul:install': {{ c.install|string|lower }}, if you want to install Consul
        you need to set it to 'true'.

{%- endif %}
