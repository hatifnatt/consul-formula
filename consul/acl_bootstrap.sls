{% from slspath ~ "/map.jinja" import consul as c -%}
include:
  - .config

# Quick and dirty policy bootstrapping. So much dirty template programming...
# NB! master token in env variables is not secure, can be easily revealed via salt.show_sls
# BEGIN Policy bootstrap check
{%- if 'policy_bootstrap' in c %}
consul_wait:
  cmd.run:
    - name: sleep 10
    - onchanges:
      - file: consul_config
      - service: consul_service

consul_acl_support:
  test.configurable_test_state:
    - name: Is ACL support enabled?
    - result: {{ c.config.data.acl.enabled|default(False) }}
    - changes: False
    - comment: "Consul ACL enabled: {{ c.config.data.acl.enabled|default(False) }}"

{% for policy in c.policy_bootstrap -%}

# Create policies
{% if policy.ensure == 'create' -%}
consul_policy_{{ policy.name }}_{{ policy.ensure }}:
  cmd.run:
    - name: |
        consul acl policy create -name="{{ policy.name }}" -description="{{ policy.description }}" -rules=- <<EOF
        {%- filter indent(8) %}
{{ policy.rules|json(indent=2) }}
        {%- endfilter %}
        EOF
    - env:
      - CONSUL_HTTP_TOKEN: {{ c.config.data.acl.tokens.initial_management }}
    - unless: consul acl policy list | grep -q '^{{ policy.name }}\:'
    - require:
      - cmd: consul_wait
      - test: consul_acl_support

# Delete policies
{% elif policy.ensure == 'delete' -%}
consul_policy_{{ policy.name }}_{{ policy.ensure }}:
  cmd.run:
    - name: consul acl policy delete -name="{{ policy.name }}"
    - env:
      - CONSUL_HTTP_TOKEN: {{ c.config.data.acl.tokens.initial_management }}
    - onlyif: consul acl policy list | grep -q '^{{ policy.name }}\:'
    - require:
      - cmd: consul_wait
      - test: consul_acl_support

# Update policies
{% elif policy.ensure == 'update' -%}
consul_policy_{{ policy.name }}_{{ policy.ensure }}:
  cmd.run:
    - name: |
        consul acl policy update -name="{{ policy.name }}" -description="{{ policy.description }}" -rules=- <<EOF
        {%- filter indent(8) %}
{{ policy.rules|json(indent=2) }}
        {%- endfilter %}
        EOF
    - env:
      - CONSUL_HTTP_TOKEN: {{ c.config.data.acl.tokens.initial_management }}
    - onlyif: consul acl policy list | grep -q '^{{ policy.name }}\:'
    - require:
      - cmd: consul_wait
      - test: consul_acl_support

{% endif -%}
{% endfor -%}

# Apply policies to anonymous token
# Super wonky implementation
{%- if 'anonymous_token' in c and 'policies' in c.anonymous_token and c.anonymous_token.policies|length > 0 %}
{%- set current_anon_policies = salt.cmd.shell("CONSUL_HTTP_TOKEN=" ~ c.config.data.acl.tokens.master ~ " consul acl token read -id='anonymous' 2>/dev/null | grep -o '\- .*$'", output_loglevel='quiet')|default('--- []', True)|load_yaml %}
{%- set anonymous_policies = c.anonymous_token.policies|join('" -policy-name="') %}
{%- if c.anonymous_token.policies|sort != current_anon_policies|sort %}
consul_anonymous_token_update:
  cmd.run:
    - name: consul acl token update -id="anonymous" -policy-name="{{ anonymous_policies }}"
    - env:
      - CONSUL_HTTP_TOKEN: {{ c.config.data.acl.tokens.initial_management }}
    - require:
      - cmd: consul_wait
      - test: consul_acl_support
{%- else %}
consul_anonymous_token_update:
  test.show_notification:
    - name: no need to update consul anonymous policies
    - text: No need to update consul anonymous policies
{%- endif %}
{%- endif %}

# Create agent token
{%- if 'agent_token' in c and 'policies' in c.agent_token and c.agent_token.policies|length > 0 %}
{%- set agent_policies = c.agent_token.policies|join('" -policy-name="') %}
consul_agent_token_create:
  cmd.run:
    - name: consul acl token create -description="Salt Created Agent Token" -policy-name="{{ agent_policies }}"
    - env:
      - CONSUL_HTTP_TOKEN: {{ c.config.data.acl.tokens.initial_management }}
    - unless: consul acl token list | grep -q "Salt Created Agent Token"
    - require:
      - cmd: consul_wait
      - test: consul_acl_support

# Update agent token if any changes in policies list
{%- set agent_token_id = salt.cmd.shell("CONSUL_HTTP_TOKEN=" ~ c.config.data.acl.tokens.initial_management ~ " consul acl token list 2>/dev/null | grep -B1 'Salt Created Agent Token' | grep -oP 'AccessorID\:\s+ \K(.*)'", output_loglevel='quiet')|default('', True) %}
{%- if agent_token_id %}
{%-   set current_agent_policies = salt.cmd.shell("CONSUL_HTTP_TOKEN=" ~ c.config.data.acl.tokens.initial_management ~ " consul acl token read -id " ~ agent_token_id ~ " 2>/dev/null | grep -o '\- .*$'", output_loglevel='quiet')|default('--- []', True)|load_yaml %}
{%-     if c.agent_token.policies|sort != current_agent_policies|sort and agent_token_id %}
consul_agent_token_update:
  cmd.run:
    - name: consul acl token update -id="{{ agent_token_id }}" -policy-name="{{ agent_policies }}"
    - env:
      - CONSUL_HTTP_TOKEN: {{ c.config.data.acl.tokens.initial_management }}
    - require:
      - cmd: consul_wait
      - test: consul_acl_support
{%-     endif %}
{%- endif %}
{%- endif %}

# END Policy bootstrap check
{%- endif %}
