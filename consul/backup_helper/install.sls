{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import consul as c %}

{#- Install backup helper script #}
{%- if c.backup_helper.install or (c.backup_helper is sameas true) %}
consul_backup_helper_install_backup_dir:
  file.directory:
    - name: {{ c.backup_dir }}
    - user: {{ c.user }}
    - group: {{ c.group }}
    - mode: 750
    - makedirs: true

consul_backup_helper_install_script:
  file.managed:
    - name: /usr/local/bin/consul_backup
    - source: salt://{{ tplroot }}/files/backup_helper.sh.jinja
    - mode: 755
    - template: jinja
    - context:
        tplroot: {{ tplroot }}

{#- Bash autocompletion for consul is not selected for installation #}
{%- else %}
consul_backup_helper_install_notice:
  test.show_notification:
    - name: consul_backup_helper_install
    - text: |
        Backup helper script is not selected for installation, current value
        for 'consul:backup_helper:install': {{ c.backup_helper.install|string|lower }},
        if you want to install Backup helper script for Consul you need to set it to 'true'.

{%- endif %}
