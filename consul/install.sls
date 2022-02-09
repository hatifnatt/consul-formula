{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import consul as c %}
include:
{%- if c.use_upstream in ('binary', 'archive') %}
  - .binary.install
{%- elif c.use_upstream in ('repo', 'package') %}
  - .package.install
{%- endif %}
