file_exports:
  file.managed:
    - name: /etc/exports
    - source: salt://files/nfs/exports
    - user: root
    - group: root
    - mode: 644

