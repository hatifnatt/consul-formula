consul_backup_helper_clean_script:
  file.absent:
    - name: /usr/local/bin/consul_backup
