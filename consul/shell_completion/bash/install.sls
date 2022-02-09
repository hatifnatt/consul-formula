{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import consul as c %}

{#- Install systemwide bash autocomplete for consul #}
{%- if c.shell_completion.bash.install %}
  {#- Install bash autocompletion package first #}
consul_shell_completion_bash_install_package:
  pkg.installed:
    - name: {{ c.shell_completion.bash.package }}

consul_shell_completion_bash_install_completion:
  file.managed:
    - name: {{  salt['file.join'](c.shell_completion.bash.dir, 'consul') }}
    - mode: 644
    - makedirs: true
    - contents: |
        complete -C {{ c.bin }} consul

{#- Bash autocompletion for consul is not selected for installation #}
{%- else %}
consul_shell_completion_bash_install_notice:
  test.show_notification:
    - name: consul_shell_completion_bash_install
    - text: |
        Bash autocompletion for Consul is not selected for installation, current value
        for 'consul:shell_completion:bash:install': {{ c.shell_completion.bash.install|string|lower }},
        if you want to install Bash autocompletion for Consul you need to set it to 'true'.

{%- endif %}
