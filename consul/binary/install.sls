{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import consul as c %}
{% set conf_dir = salt['file.dirname'](c['params']['config-file']) -%}

include:
  - {{ tplroot }}.shell_completion.bash.install
  - {{ tplroot }}.backup_helper.install
  - {{ slsdotpath }}.service.install

{# Install prerequisies #}
consul_binary_install_prerequisites:
  pkg.installed:
    - pkgs: {{ c.prereq_pkgs|tojson }}

{# Create group and user #}
consul_binary_install_group:
  group.present:
    - name: {{ c.group }}
    - system: True

consul_binary_install_user:
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
      - group: consul_binary_install_group

{# Create directories #}
consul_binary_install_bin_dir:
  file.directory:
    - name: {{ salt['file.dirname'](c.bin) }}
    - makedirs: True

{# Download archive, extract archive install binary to it's place #}
{# TODO: Download and validate SHA file with gpg? https://www.hashicorp.com/security.html #}
consul_binary_install_download_archive:
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

consul_binary_install_extract_bin:
  archive.extracted:
    - name: {{ c.temp_dir }}/{{ c.version }}
    - source: {{ c.temp_dir }}/{{ c.version }}/consul_{{ c.version }}_linux_amd64.zip
    - skip_verify: True
    - enforce_toplevel: False
    - require:
      - file: consul_binary_install_download_archive
    - unless: test -f {{ c.bin }}-{{ c.version }}

consul_binary_install_install_bin:
  file.rename:
    - name: {{ c.bin }}-{{ c.version }}
    - source: {{ c.temp_dir }}/{{ c.version }}/{{ salt['file.basename'](c.bin) }}
    - require:
      - file: consul_binary_install_bin_dir
    - watch:
      - archive: consul_binary_install_extract_bin

{# Create symlink into system bin dir #}
consul_binary_install_bin_symlink:
  file.symlink:
    - name: {{ c.bin }}
    - target: {{ c.bin }}-{{ c.version }}
    - force: True
    - require:
      - archive: consul_binary_install_extract_bin
      - file: consul_binary_install_install_bin
    - require_in:
      - sls: {{ tplroot }}.shell_completion.bash.install

{# Fix problem with service startup due SELinux restrictions on RedHat falmily OS-es
thx. https://github.com/saltstack-formulas/consul-formula/issues/49 for idea #}
{% if grains['os_family'] == 'RedHat' -%}
consul_binary_install_bin_restorecon:
  module.run:
  {#- Workaround for deprecated `module.run` syntax, subject to change in Salt 3005 #}
  {%- if 'module.run' in salt['config.get']('use_superseded', [])
      or grains['saltversioninfo'] >= [3005] %}
    - file.restorecon:
        - {{ c.bin }}-{{ c.version }}
  {%- else %}
    - name: file.restorecon
    - path: {{ c.bin }}-{{ c.version }}
  {%- endif %}
    - require:
      - file: consul_binary_install_install_bin
    - require_in:
      - sls: {{ tplroot }}.shell_completion.bash.install
    - onlyif: "LC_ALL=C restorecon -vn {{ c.bin }}-{{ c.version }} | grep -q 'Would relabel'"
{% endif -%}

{# Remove temporary files #}
consul_binary_install_cleanup:
  file.absent:
    - name: {{ c.temp_dir }}
    - require_in:
      - sls: {{ tplroot }}.backup_helper.install
      - sls: {{ slsdotpath }}.service.install
