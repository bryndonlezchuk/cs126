base:
  '*':
#    - pkgs/webserver
    - user
    - pkgs.htop
    - pkgs.vim
#    - pkgs.iptables
    - selinux
  'class:CS126':
    - match: grain
    - pkgs.webserver
  'role:webserver':
    - match: grain
    - pkgs.webserver
  'role:firewall':
    - match: grain
    - pkgs.iptables
  'role:nfs':
    - match: grain
    - service.nfs
