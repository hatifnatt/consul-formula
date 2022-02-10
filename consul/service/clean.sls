{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import consul as c %}

{#- Stop and disable service #}
consul_service_clean_dead:
  service.dead:
    - name: {{ c.service.name }}

consul_service_clean_disabled:
  service.disabled:
    - name: {{ c.service.name }}
