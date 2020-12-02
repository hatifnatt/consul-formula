{% from "./map.jinja" import consul as c -%}
{# Get 'current working directory' - path where current state file is located #}
{% set tplroot = tplfile.split('/')[:-1] | join('/') -%}
{% set conf_dir = salt['file.dirname'](c['params']['config-file']) -%}
{# Install prerequisies #}
consul_prerequisites:
  pkg.installed:
    - pkgs: {{ c.prereq_pkgs|tojson }}

{# Create group and user #}
consul_group:
  group.present:
    - name: {{ c.group }}
    - system: True

consul_user:
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
      - group: consul_group

{# Create directories #}
consul_conf_dir:
  file.directory:
    - name: {{ conf_dir }}
    - user: {{ c.user }}
    - group: {{ c.group }}
    - dir_mode: 755

consul_bin_dir:
  file.directory:
    - name: {{ salt['file.dirname'](c.bin) }}
    - makedirs: True

{# Download archive, extract archive install binary to it's place #}
{# TODO: Download and validate SHA file with gpg? https://www.hashicorp.com/security.html #}
consul_download_archive:
  file.managed:
    - name: {{ c.temp_dir }}/{{ c.version }}/consul_{{ c.version }}_linux_amd64.zip
    - source: {{ c.download_remote }}{{ c.version }}/consul_{{ c.version }}_linux_amd64.zip
    {%- if c.skip_verify %}
    - skip_verify: True
    {%- else %}
    - source_hash: {{ c.source_hash_remote }}{{ c.version }}/consul_{{ c.version }}_SHA256SUMS
    {%- endif %}
    - makedirs: True
    - unless: test -f {{ c.bin }}-{{ c.version }}

consul_extract_bin:
  archive.extracted:
    - name: {{ c.temp_dir }}/{{ c.version }}
    - source: {{ c.temp_dir }}/{{ c.version }}/consul_{{ c.version }}_linux_amd64.zip
    - skip_verify: True
    - enforce_toplevel: False
    - require:
      - file: consul_download_archive
    - unless: test -f {{ c.bin }}-{{ c.version }}

consul_install_bin:
  file.rename:
    - name: {{ c.bin }}-{{ c.version }}
    - source: {{ c.temp_dir }}/{{ c.version }}/{{ salt['file.basename'](c.bin) }}
    - require:
      - file: consul_bin_dir
    - watch:
      - archive: consul_extract_bin

{# Create symlink into system bin dir #}
consul_bin_symlink:
  file.symlink:
    - name: {{ c.bin }}
    - target: {{ c.bin }}-{{ c.version }}
    - force: True
    - require:
      - archive: consul_extract_bin
      - file: consul_install_bin

# Install systemwide autocomplete for bash
{% if c.bash_autocomplete and salt.file.directory_exists('/etc/bash_completion.d') -%}
consul_bash_autocomplete:
  file.managed:
    - name: /etc/bash_completion.d/consul
    - mode: 644
    - contents: |
        complete -C {{ c.bin }} consul
{% endif -%}

# Install systemd service file
{%- if grains.init == 'systemd' %}
consul_systemd_unit:
  file.managed:
    - name: /usr/lib/systemd/system/{{ c.service_name }}.service
    - source: salt://{{ tplroot }}/files/consul.service.jinja
    - user: {{ c.root_user }}
    - group: {{ c.root_group }}
    - mode: 644
    - template: jinja
    - context:
        tplroot: {{ tplroot }}
    - watch_in:
      - module: consul_reload_systemd

{# Reload systemd after new unit file added, like `systemctl daemon-reload` #}
consul_reload_systemd:
  module.wait:
  {#- Workaround for deprecated `module.run` syntax, subject to change in Salt 3005 #}
  {%- if 'module.run' in salt['config.get']('use_superseded', [])
      or grains['saltversioninfo'] >= [3005] %}
    - service.systemctl_reload: {}
  {%- else %}
    - name: service.systemctl_reload
  {%- endif %}
{% endif -%}

# Install backup helper script
{% if c.backup_helper -%}
consul_backup_dir:
  file.directory:
    - name: {{ c.backup_dir }}
    - user: {{ c.user }}
    - group: {{ c.group }}
    - mode: 750
    - makedirs: True

consul_backup_helper:
  file.managed:
    - name: /usr/local/bin/consul_backup
    - source: salt://{{ tplroot }}/files/backup_helper.sh.jinja
    - mode: 755
    - template: jinja
    - context:
        tplroot: {{ tplroot }}
{% endif -%}

{# Remove temporary files #}
consul_cleanup:
  file.absent:
    - name: {{ c.temp_dir }}
