# Class:: bird::params
#
class bird::params {
  case $::osfamily {
    'Debian': {
      $daemon_name_v4   = 'bird'
      $daemon_name_v6   = 'bird6'
      $config_dir       = '/etc/bird'
      $config_path_v4   = "${config_dir}/bird.conf"
      $config_path_v6   = "${config_dir}/bird6.conf"
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily}")
    }
  } # Case $::operatingsystem
} # Class:: bird::params
