define srcomp_kiosk::systemd_service (
  $command,
  $user,
  $desc,
  $dir = undef,
  $memory_limit = undef,
  $depends = ['network.target'],
  $part_of = undef,
  $environment = undef,
  $restart='on-failure',
  $wanted_by='multi-user.target',
  $subs = []
) {
  $service_name = "${title}.service"
  $service_file = "/etc/systemd/system/${service_name}"

  $service_description = $desc
  $start_dir = $dir
  $start_command = $command
  if $depends != undef {
    $depends_str = join($depends, ' ')
  }

  file { $service_file:
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('srcomp_kiosk/systemd_service.erb'),
  } ->
  file { "/etc/systemd/system/${wanted_by}.wants/${service_name}":
    ensure  => link,
    target  => $service_file,
  } ->
  exec { "${title}-systemd-load":
    provider  => 'shell',
    command   => 'systemctl daemon-reload',
    subscribe => File[$service_file],
  } ->
  service { $title:
    ensure    => running,
    enable    => true,
    subscribe => union([File[$service_file]], $subs),
  }
}
