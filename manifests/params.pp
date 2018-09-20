# Class:: bird::params
#
class bird::params {
  case $::osfamily {
    'Debian': {
      $daemon_name_v4   = 'bird'
      $daemon_name_v6   = 'bird6'
      $daemon_user      = $daemon_name_v4
      $daemon_group     = $daemon_name_v4
      $config_dir       = '/etc/bird'
      $config_path_v4   = "${config_dir}/bird.conf"
      $config_path_v6   = "${config_dir}/bird6.conf"
      $daemon_config    = "${config_dir}/envvars"
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily}")
    }
  } # Case $::operatingsystem
} # Class:: bird::params
