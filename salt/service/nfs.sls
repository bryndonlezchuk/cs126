include:
  - service.nfs-config

nfs-server:
  service.running:
    - name: nfs
    - enable: True

nfs-utils:
  pkg.installed:
    - pkgs:
      - nfs-utils
      - nfs-utils-lib

