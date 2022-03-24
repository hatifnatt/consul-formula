{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import consul as c %}

include:
  - {{ tplroot }}.shell_completion.bash.clean
  - {{ tplroot }}.backup_helper.clean
  - {{ tplroot }}.service.clean

consul_package_clean:
  pkg.removed:
    - pkgs:
    {%- for pkg in c.package.pkgs %}
      - {{ pkg }}
    {%- endfor %}

{#- Remove user and group #}
consul_package_clean_user:
  user.absent:
    - name: {{ c.user }}

consul_package_clean_group:
  group.absent:
    - name: {{ c.group }}
