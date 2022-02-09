{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import consul as c %}

{#- Remove systemwide bash autocomplete for consul #}
consul_shell_completion_bash_install_completion:
  file.absent:
    - name: {{  salt['file.join'](c.shell_completion.bash.dir, 'consul') }}
