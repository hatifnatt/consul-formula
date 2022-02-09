{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import consul as c %}
{#- Find all consul binaries with version i.e. /usr/local/bin/consul-1.11.2 etc. #}
{%- set consul_versions = salt['file.find'](c.bin ~ '-*',type='fl') %}

include:
  - {{ tplroot }}.shell_completion.bash.clean
  - {{ tplroot }}.backup_helper.clean
  - {{ slsdotpath }}.service.clean

{#- Remove symlink into system bin dir #}
consul_binary_clean_bin_symlink:
  file.absent:
    - name: {{ c.bin }}

{%- for binary in consul_versions %}
  {%- set version = binary.split('-')[-1] %}
consul_binary_clean_bin_v{{ version }}:
  file.absent:
    - name: {{ binary }}
    - require:
      - file: consul_binary_clean_bin_symlink

{%- endfor %}

{#- Remove user and group #}
consul_binary_clean_user:
  user.absent:
    - name: {{ c.user }}

consul_binary_clean_group:
  group.absent:
    - name: {{ c.group }}
