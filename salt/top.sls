base:
  '*':
    - pkgs/webserver
    - user
    - pkgs.htop
    - pkgs.vim
    - pkgs.iptables
    - selinux
  'class:CS126':
    - webserver
