class srcomp_kiosk::tunnel ( $remote_ssh_port = lookup('remote_ssh_port') ) {
  package { 'autossh':
    ensure => installed,
  }

  $home_dir = '/home/autossh'
  $ssh_dir = "${home_dir}/.ssh"
  $key_file = "${ssh_dir}/id_ed25519"

  $tunnel_host = 'srcomp.studentrobotics.org'

  user { 'autossh':
    ensure      => present,
    comment     => 'A user for port forwarding',
    gid         => 'users',
    managehome  => true,
    shell       => '/usr/sbin/nologin',
  } ->
  file { $ssh_dir:
    ensure  => directory,
    owner   => 'autossh',
    group   => 'users',
    mode    => '0700',
  } ->
  exec { "ssh-keyscan ${tunnel_host} for tunnel user":
    command => "/usr/bin/ssh-keyscan ${tunnel_host} > ${ssh_dir}/known_hosts",
    cwd     => $home_dir,
    user    => 'autossh',
    creates => "${ssh_dir}/known_hosts",
  } ->
  exec { 'Create ssh key for tunnel user':
    command => "/usr/bin/ssh-keygen -t ed25519 -f ${key_file}",
    cwd     => $home_dir,
    user    => 'autossh',
    creates => $key_file,
  } ->
  srcomp_kiosk::systemd_service { 'autossh-tunnel':
    desc        => 'AutoSSH tunneling SSH access to the public compbox.',
    user        => 'autossh',
    command     => "/usr/bin/autossh -M 0 -o 'ServerAliveInterval 30' -o 'ExitOnForwardFailure yes' -N -R ${remote_ssh_port}:localhost:22 -i ${key_file} autossh@${tunnel_host}",
    environment => 'AUTOSSH_GATETIME=0',
    require     => Package['autossh'],
    subs        => [Exec['Create ssh key for tunnel user']],
  }
}
