class srcomp_kiosk {

  $opt_kioskdir = '/opt/srcomp-kiosk'
  $etc_kioskdir = '/etc/srcomp-kiosk'
  $kiosk_logdir = '/var/log/srcomp-kiosk'
  $user         = 'pi'
  $user_home    = "/home/${user}"
  $user_config  = "${user_home}/.config"
  $user_ssh     = "${user_home}/.ssh"
  $url          = hiera('url')
  $browser_type = hiera('browser_type')
  $timezone     = hiera('timezone')

  $compbox_ip   = hiera('compbox_ip')
  $compbox_hostname = hiera('compbox_hostname')

  $is_newer_pi = $::architecture == 'armv7l'

  include 'srcomp_kiosk::hostname'
  include 'srcomp_kiosk::tunnel'

  class { '::ntp':
    servers => [$compbox_hostname],
  }

  exec { "/usr/bin/timedatectl set-timezone ${timezone}":
    unless  => "/usr/bin/timedatectl status | grep 'Time zone: ${timezone}'",
  }

  package { ["unclutter"
            ,"python3-yaml"
            ,"x11-xserver-utils"
            ,"screen"
            ,"xdotool"
            ,"htop"
            ,"ntpstat"  #  but `ntpq -p` is more useful
            ]:
    ensure => installed,
  }

  if $is_newer_pi {
    package { ["firefox-esr"]:
      ensure => installed,
    }
  } else {
    package { ["firefox-esr"]:
      # Pin the specific version already present on the Pis to ensure that we
      # don't accidentally upgrade them.
      ensure => '52.9.0esr-1~deb9u1',
    }
  }

  package { ["xscreensaver"]:
    ensure => absent,
  }

  File {
    owner   => $user,
    group   => $user,
  }

  # Config
  file { $etc_kioskdir:
    ensure => directory,
  }

  file { "${etc_kioskdir}/config.yaml":
    ensure  => file,
    content => "url: '${url}'",
    require => File[$etc_kioskdir],
  }

  # User config
  file { $user_home:
    ensure  => directory,
  }

  file { "${user_home}/show-procs":
    ensure  => file,
    mode    => '0755',
    content => 'ps aux | grep --color -E "(unclutter|icew|fire|chrom|python)"',
  }

  file { "${user_home}/.bash_aliases":
    ensure  => file,
    mode    => '0644',
    content => 'export DISPLAY=:0',
  }

  # Easy logins
  file { $user_ssh:
    ensure  => directory,
    mode    => '0700',
  }

  file { "${user_ssh}/authorized_keys":
    ensure  => file,
    mode    => '0600',
    # TODO: Put in hiera?
    source  => 'puppet:///modules/srcomp_kiosk/pi-authorized_keys',
    require => File[$user_ssh],
  }

  # Autostart
  file { $user_config:
    ensure  => directory,
    require => File[$user_home],
  }

  $autostart_dir = "${user_config}/autostart"
  file { $autostart_dir:
    ensure  => directory,
    require => File[$user_config],
  }

  $kiosk_runner = '/usr/local/bin/srcomp-kiosk'
  file { "${autostart_dir}/kiosk.desktop":
    ensure  => file,
    content => template('srcomp_kiosk/kiosk.desktop.erb'),
    require => File[$autostart_dir],
  }

  file { $kiosk_logdir:
    ensure  => directory,
  }

  $service_name = 'srcomp-kiosk'
  $service_pid_file = "/tmp/${service_name}.pid"
  file { $service_pid_file:
    ensure  => file,
  }

  $kiosk_script = "${opt_kioskdir}/kiosk.py"
  if $is_newer_pi {
    $start_command = "$kiosk_script --browser-type chromium-browser --browser-path ${browser_type}"
  } else {
    $start_command = "$kiosk_script --browser-type ${browser_type}"
  }
  $log_dir = $kiosk_logdir
  file { $kiosk_runner:
    ensure  => file,
    content => template('srcomp_kiosk/service.erb'),
    mode    => '0755',
    require => [
      File[$kiosk_script],
      File[$kiosk_logdir],
      File["${etc_kioskdir}/config.yaml"],
    ],
  }

  file { $opt_kioskdir:
    ensure  => directory,
  }

  file { $kiosk_script:
    ensure  => file,
    source  => 'puppet:///modules/srcomp_kiosk/kiosk.py',
    mode    => '0755',
    require => File[$opt_kioskdir],
  }

  if !$is_newer_pi {
    file { "${opt_kioskdir}/firefox-profile":
      ensure  => directory,
      recurse => true,
      purge   => true,
      force   => true,
      source  => 'puppet:///modules/srcomp_kiosk/firefox-profile',
      mode    => '0755',
      before  => File[$kiosk_runner],
      require => File[$opt_kioskdir],
    }
  }

  exec { 'Start kiosk':
    command => "/bin/su - -c 'DISPLAY=:0.0 ${kiosk_runner} start' ${user}",
    cwd     => $user_home,
    unless  => "${kiosk_runner} status",
    require => File[$kiosk_runner],
  }

  host { $compbox_hostname:
    ensure => present,
    ip     => $compbox_ip,
  }
}
