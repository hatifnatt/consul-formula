{% from "./map.jinja" import consul as c -%}
include:
  - .install
  - .config
  {%- if c.config.data.acl.enabled|default(False) %}
  - .acl_bootstrap
  {%- endif %}
