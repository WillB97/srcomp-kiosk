class srcomp_kiosk {

  $opt_kioskdir = '/opt/srcomp-kiosk'
  $etc_kioskdir = '/etc/srcomp-kiosk'
  $kiosk_logdir = '/var/log/srcomp-kiosk'
  $user         = 'pi'
  $user_home    = "/home/${user}"
  $user_config  = "${user_home}/.config"
  $user_ssh     = "${user_home}/.ssh"
  $url          = hiera('url')
  $timezone     = hiera('timezone')

  $venue_compbox_ip       = hiera('venue_compbox_ip')
  $venue_compbox_hostname = hiera('venue_compbox_hostname')

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
            ,"chromium-browser"
            ,"ntpstat"  #  but `ntpq -p` is more useful
            ]:
    ensure => installed,
  }

  # Disable screen blanking
  package { ["xscreensaver"]:
    ensure => absent,
  }
  file { "/etc/X11/xorg.conf.d":
    ensure  => directory,
  }
  file { "/etc/X11/xorg.conf.d/10-blanking.conf":
    ensure  => file,
    source  => 'puppet:///modules/srcomp_kiosk/10-blanking.conf',
    require => File["/etc/X11/xorg.conf.d"],
  }

  # Remove undervoltage warnings
  package { ["lxplug-ptbatt"]:
    ensure => absent,
  }

  File {
    owner   => $user,
    group   => $user,
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

  $base_kiosk_args = "--kiosk --enable-kiosk-mode --enabled"
  $base_kiosk_opts = "--no-sandbox --disable-smooth-scrolling --disable-java --disable-restore-session-state --disable-sync --disable-translate"
  $low_power_kiosk_args = "--disable-low-res-tiling --enable-low-end-device-mode --disable-composited-antialiasing --disk-cache-size=1 --media-cache-size=1"
  if $is_newer_pi {
    if hiera('is_livestream') {
      # https://www.youtube.com/embed/${livestream_id}?autoplay=1&controls=0&hd=1
      $kiosk_args = "--kiosk --no-user-gesture-required --start-fullscreen --autoplay-policy=no-user-gesture-required"
    } else {
      $kiosk_args = "${base_kiosk_args} ${base_kiosk_opts}"
    }
  } else {
    $kiosk_args = "${base_kiosk_args} ${base_kiosk_opts} ${low_power_kiosk_args}"
  }

  srcomp_kiosk::systemd_service { 'srcomp-kiosk':
    desc        => 'A fullscreen chromium browser in kiosk mode.',
    user        => 'pi',
    command     => "/usr/bin/chromium-browser ${kiosk_args} '${url}'",
    environment => 'DISPLAY=:0',
    wanted_by   => 'graphical.target',
    part_of     => 'graphical.target',
    depends     => undef,
    restart     => 'always',
    wanted_by   => 'graphical.target',
  }

  host { $venue_compbox_hostname:
    ensure => present,
    ip     => $venue_compbox_ip,
  }
}
