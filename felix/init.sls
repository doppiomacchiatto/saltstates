felix:
  group.present:
    - gid: 1337
    - require_in:
      - user: felix
  user.present:
    - fullname: Felix Hummel
    - home: /home/felix
    - uid: 1337
    - shell: /bin/bash
    - groups:
      - felix
      - adm
      - sudo
    - optional_groups:
      - cdrom
      - dip
      - lpadmin
      - plugdev
      - sambashare
      - fuse
      - disk

# There should be a better way to clean up things here. I guess there is some skeleton, but I'm too lazy to find it now.
{% set dirs = 'Documents Music Pictures Public Templates Videos'.split() %}
{% for dir in dirs %}
/home/felix/{{ dir }}:
  file.absent:
    - require:
      - user: felix
{% endfor %}

{%- from 'macros.sls' import configs with context -%}
{{ configs('felix') }}

/home/felix/.gitconfig.d/user:
  file.managed:
    - source: salt://felix/gitconfig_user
    - user: felix
    - group: felix
    - mode: 600
    - template: jinja
    - context:
      full_name: {{ pillar['users']['felix']['name'] }}
      email: {{ pillar['users']['felix']['email'] }}
    - require:
      - cmd: felix_configs_init

/home/felix/.gitconfig.d/local:
  file.managed:
    - source: salt://felix/gitconfig_local
    - user: felix
    - group: felix
    - mode: 600
    - require:
      - cmd: felix_configs_init

# user0 is my convention for first user with auto-generated uid
remove_default_user:
  user.absent:
    - name: user0
    - require:
      - user: felix
  file.absent:
    - name: /home/user0

{% for host, fingerprint in salt['pillar.get']('users:felix:known_hosts').items() %}
{{ host }}:
  ssh_known_hosts.present:
    - user: felix
    - fingerprint: {{ fingerprint }}
    - require:
      - user: felix
{% endfor %}

