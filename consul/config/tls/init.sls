{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import consul as c %}
{%- from tplroot ~ '/macros.jinja' import format_kwargs, build_source %}

{%- if c.install %}
  {#- Manage Consul TLS key and certificate #}
include:
  - {{ tplroot }}.service

  {%- if c.tls.self_signed
      and 'key_file' in c.config.data
      and 'cert_file' in c.config.data
  %}
    {#- Create self sifned TLS (SSL) certificate #}
consul_config_tls_prereq_packages:
  pkg.installed:
    - pkgs: {{ c.tls.packages|json }}

consul_config_tls_selfsigned_key:
  x509.private_key_managed:
    - name: {{ c.config.data.key_file }}
    - user: {{ c.user }}
    - group: {{ c.group }}
    - mode: 640
    - makedirs: true
    - require:
      - pkg: consul_config_tls_prereq_packages

consul_config_tls_selfsigned_cert:
  x509.certificate_managed:
    - name: {{ c.config.data.cert_file }}
    - signing_private_key: {{ c.config.data.key_file }}
    {{- format_kwargs(c.tls.cert_params) }}
    - user: {{ c.user }}
    - group: {{ c.group }}
    - mode: 640
    - makedirs: true
    - require:
      - x509: consul_config_tls_selfsigned_key
    - watch_in:
      - service: consul_service_{{ c.service.status }}

  {%- elif not c.tls.self_signed
      and 'key_file' in c.config.data
      and 'cert_file' in c.config.data
  %}

consul_config_tls_provided_key:
  file.managed:
    - name: {{ c.config.data.key_file }}
    - source:
    {{- build_source(c.tls.key_file_source, path_prefix='files/tls') }}
    - user: {{ c.user }}
    - group: {{ c.group }}
    - mode: 640
    - makedirs: true
    - watch_in:
      - service: consul_service_{{ c.service.status }}

consul_config_tls_provided_cert:
  file.managed:
    - name: {{ c.config.data.cert_file }}
    - source:
    {{- build_source(c.tls.cert_file_source, path_prefix='files/tls') }}
    - user: {{ c.user }}
    - group: {{ c.group }}
    - mode: 640
    - makedirs: true
    - watch_in:
      - service: consul_service_{{ c.service.status }}

  {#- Not enough data to configure TLS #}
  {%- else %}
consul_config_tls_skipped:
  test.show_notification:
    - name: consul_config_tls_skipped
    - text: |
        Not enough data to configure TLS.
        You must provide values for `key_file` and `cert_file` in pillars
        Current values:
        consul:config:data:key_file: '{{ c.config.data.get('key_file', '') }}'
        consul:config:data:cert_file: '{{ c.config.data.get('cert_file', '') }}'
        
        Also you need to enable self signed certificate generation
        consul:tls:self_signed: '{{ c.tls.self_signed|string|lower }}'
        
        OR provide existing key and certificate files
        consul:tls:key_file_source: '{{ c.tls.get('key_file_source', '') }}'
        consul:tls:cert_file_source: '{{ c.tls.get('cert_file_source', '') }}'
        Note, formula have default values 'tls.key', 'tls.crt' but actual files
        are not provided with formula, you neet to put them into folder 'consul/files/tls'
        on salt file server.

{%- endif %}

{#- Consul is not selected for installation #}
{%- else %}
consul_config_tls_install_notice:
  test.show_notification:
    - name: consul_config_tls_install_notice
    - text: |
        Consul is not selected for installation, current value
        for 'consul:install': {{ c.install|string|lower }}, if you want to install Consul
        you need to set it to 'true'.

{%- endif %}
