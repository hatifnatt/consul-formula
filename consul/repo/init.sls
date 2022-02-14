{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import consul as c %}
{%- from tplroot ~ '/macros.jinja' import format_kwargs %}

{%- if c.install %}
  {#- If consul:use_upstream is 'repo' or 'package' official repo will be configured #}
  {%- if c.use_upstream in ('repo', 'package') %}

    {#- Install required packages if defined #}
    {%- if c.repo.prerequisites %}
consul_repo_prerequisites:
  pkg.installed:
    - pkgs: {{ c.repo.prerequisites|tojson }}
    {%- endif %}

    {#- If only one repo configuration is present - convert it to list #}
    {%- if c.repo.config is mapping %}
      {%- set configs = [c.repo.config] %}
    {%- else %}
      {%- set configs = c.repo.config %}
    {%- endif %}
    {%- for config in configs %}
consul_repo_{{ loop.index0 }}:
  pkgrepo.managed:
    {{- format_kwargs(config) }}
    {%- endfor %}

  {#- Another installation method is selected #}
  {%- else %}
consul_repo_install_method:
  test.show_notification:
    - name: consul_repo_install_method
    - text: |
        Another installation method is selected. Repo configuration is not required.
        If you want to configure repository set 'consul:use_upstream' to 'repo' or 'package'.
        Current value of consul:use_upstream: '{{ c.use_upstream }}'
  {%- endif %}

{#- Consul is not selected for installation #}
{%- else %}
consul_repo_install_notice:
  test.show_notification:
    - name: consul_repo_install
    - text: |
        Consul is not selected for installation, current value
        for 'consul:install': {{ c.install|string|lower }}, if you want to install Consul
        you need to set it to 'true'.

{%- endif %}
