{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import consul as c %}
{%- from tplroot ~ '/macros.jinja' import format_kwargs %}

{#- Remove any configured repo form the system, use with care if multiple HashiCorp porducts are installed #}
{#- If only one repo configuration is present - convert it to list #}
{%- if c.repo.config is mapping %}
  {%- set configs = [c.repo.config] %}
{%- else %}
  {%- set configs = c.repo.config %}
{%- endif %}
{%- for config in configs %}
consul_repo_clean_{{ loop.index0 }}:
  pkgrepo.absent:
    - name: {{ config.name }}
{%- endfor %}
