# == Class: bird
#
# Install and configure bird
#
# === Parameters
#
# [*config_file_v4*]
#   Bird configuration file for IPv4.
#   Default: UNSET. (this value is a puppet source, example 'puppet:///modules/bgp/bird.conf').
#
# [*config_template_v4*]
#   Bird configuration template for IPv4.
#   Default: UNSET. (this value is a template source, it will be passed into the template() function).
#
# [*daemon_user*]
#   String, The service user name.
#   Default: $bird::params::daemon_name_v4
#
# [*daemon_group*]
#   String, The service group name.
#   Default: $bird::params::daemon_name_v4
#
# [*daemon_name_v6*]
#   The service name used by puppet ressource
#   Default: bird6
#
# [*daemon_name_v4*]
#   The service name used by puppet ressource
#   Default: bird
#
# [*enable_v6*]
#   Boolean for enable IPv6 (install bird6 package)
#   Default: true
#
# [*manage_conf*]
#   Boolean, global parameter to disable or enable mangagment of bird configuration files.
#   Default: true
#
# [*manage_service*]
#   Boolean, global parameter to disable or enable mangagment of bird service.
#   Default: true
#
# [*manage_service_file*]
#   Boolean, global parameter to disable or enable mangagment of bird service unit file.
#   Default: true
#
# [*daemon_service_v4*]
#   String, global parameter for location of the bird service unit file, IPv4.
#   Default: true
#
# [*daemon_service_v6*]
#   String, global parameter for location of the bird service unit file, IPv6.
#   Default: true
#
# [*service_v6_ensure*]
#   Bird IPv6 daemon ensure (shoud be running or stopped).
#   Default: running
#
# [*service_v6_enable*]
#   Boolean, enabled param of Bird IPv6 service (run at boot time).
#   Default: true
#
# [*service_v4_ensure*]
#   Bird IPv4 daemon ensure (shoud be running or stopped).
#   Default: running
#
# [*service_v4_enable*]
#   Boolean, enabled param of Bird IPv4 service (run at boot time).
#   Default: true
#
# [*config_file_v6*]
#  Bird configuration file for IPv6.
#  Default: UNSET. (this value is a puppet source, example 'puppet:///modules/bgp/bird6.conf').
#
# [*config_template_v6*]
#   Bird configuration template for IPv6.
#   Default: UNSET. (this value is a template source, it will be passed into the template() function).
#
# [*graceful_restart*]
#   Boolean, enable graceful restart for supported bird protocols [ kernal and BGP ]
#   Default: true , but requires manage_conf and manage_service_file to work
#
# === Examples
#
#  class { 'bird':
#    enable_v6       => true,
#    config_file_v4  => 'puppet:///modules/bgp/ldn/bird.conf',
#    config_file_v6  => 'puppet:///modules/bgp/ldn/bird6.conf',
#  }
#
# === Authors
#
# Sebastien Badia <http://sebastien.badia.fr/>
# Lorraine Data Network <http://ldn-fai.net/>
#
# === Copyright
#
# Copyleft 2013 Sebastien Badia
# See LICENSE file
#
class bird (
  String                       $daemon_name_v4     = $bird::params::daemon_name_v4,
  String                       $config_file_v4     = 'UNSET',
  String                       $config_template_v4 = 'UNSET',
  String                       $daemon_user        = $bird::params::daemon_user,
  String                       $daemon_group       = $bird::params::daemon_group,
  Boolean                      $enable_v6          = true,
  Boolean                      $manage_conf        = true,
  Boolean                      $manage_service     = true,
  Boolean                      $manage_service_file= true,
  String                       $daemon_service_v4  = $bird::params::daemon_service_v4,
  String                       $daemon_service_v6  = $bird::params::daemon_service_v6,
  Enum['stopped', 'running']   $service_v6_ensure  = 'running',
  Boolean                      $service_v6_enable  = true,
  Enum['stopped', 'running']   $service_v4_ensure  = 'running',
  Boolean                      $service_v4_enable  = true,
  String                       $daemon_name_v6     = $bird::params::daemon_name_v6,
  String                       $config_file_v6     = 'UNSET',
  String                       $config_template_v6 = 'UNSET',
  Boolean                      $graceful_restart   = true,
) inherits bird::params {


  package {
    $daemon_name_v4:
      ensure => installed;
  }

  if $manage_service == true {

    service {
      $daemon_name_v4:
        ensure      => $service_v4_ensure,
        enable      => $service_v4_enable,
        hasrestart  => false,
        restart     => '/usr/sbin/birdc configure',
        hasstatus   => false,
        pattern     => $daemon_name_v4,
        require     => Package[$daemon_name_v4];
    }

  }

  if $manage_service_file {

    # Deamon Service #
    file {
      $daemon_service_v4:
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template("${module_name}/daemon_service_v4.erb"),
        notify  => Service[$daemon_name_v4],
        require => Package[$daemon_name_v4],
    }

    exec {'bird_systemd_reload':
      command     => '/bin/systemctl daemon-reload',
      refreshonly => true,
    }

    # User collector here, as this needs to apply to v6 as well, IF its enabled below #
    Exec['bird_systemd_reload'] -> Service<| tag == 'bird' |>

  }

  if $manage_conf == true {

    file {
      $config_dir:
        ensure => directory,
        owner   => root,
        group   => root,
        mode    => '0755',
    }

    # Set any daemon args #
    if $graceful_restart {
      $graceful_arg = "-R "
    } else {
      $graceful_arg = undef
    }

   # If any deamon args set, concatinate them together #
   if $graceful_arg {
     $daemon_args = "${graceful_arg}"
   } else {
     $daemon_args = undef
   }

    # Deamon Config - this is consumed by v4 and v6 #
    file {
      $daemon_config:
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template("${module_name}/daemon_config.erb"),
        require => Package[$daemon_name_v4],
    }

    # User collector here, as this needs to apply to v6 as well, IF its enabled below #
    File[$daemon_config]     ~> Service<| tag == 'bird' |>

    # Bird config #
    if $config_file_v4 == 'UNSET' and $config_template_v4 == 'UNSET' {
      fail("either config_file_v4 or config_template_v4 parameter must be set (config_file_v4: ${config_file_v4}, config_template_v4: ${config_template_v4})")
    } else {
      if $config_file_v4 != 'UNSET' {
        file {
          $config_path_v4:
            ensure  => file,
            source  => $config_file_v4,
            owner   => root,
            group   => root,
            mode    => '0644',
            notify  => Service[$daemon_name_v4],
            require => Package[$daemon_name_v4];
        }
      } else {
        file {
          $config_path_v4:
            ensure  => file,
            content => template($config_template_v4),
            owner   => root,
            group   => root,
            mode    => '0644',
            notify  => Service[$daemon_name_v4],
            require => Package[$daemon_name_v4];
        }
      } # config_file_v4
    } # config_tmpl_v4
  } # manage_conf

  if $enable_v6 == true {

    package {
      $daemon_name_v6:
        ensure => installed;
    }

    if $manage_service == true {
      service {
        $daemon_name_v6:
          ensure     => $service_v6_ensure,
          enable     => $service_v6_enable,
          hasrestart => false,
          restart    => '/usr/sbin/birdc6 configure',
          hasstatus  => false,
          pattern    => $daemon_name_v6,
          require    => Package[$daemon_name_v6];
      }
    }

    if $manage_service_file == true {

      # Deamon Service #
      file {
        $daemon_service_v6:
          owner   => 'root',
          group   => 'root',
          mode    => '0644',
          content => template("${module_name}/daemon_service_v6.erb"),
          notify  => Service[$daemon_name_v6],
          require => Package[$daemon_name_v6],
      }

    }

    # Bird config #
    if $manage_conf == true {
      if $config_file_v6 == 'UNSET' and $config_template_v6 == 'UNSET' {
        fail("either config_file_v6 or config_template_v6 parameter must be set (config_file_v6: ${config_file_v6}, config_template_v6: ${config_template_v6})")
      } else {
        if $config_file_v6 != 'UNSET' {
          file {
            $config_path_v6:
              ensure  => file,
              source  => $config_file_v6,
              owner   => root,
              group   => root,
              mode    => '0644',
              notify  => Service[$daemon_name_v6],
              require => Package[$daemon_name_v6];
          }
        } else {
          file {
            $config_path_v6:
              ensure  => file,
              content => template($config_template_v6),
              owner   => root,
              group   => root,
              mode    => '0644',
              notify  => Service[$daemon_name_v6],
              require => Package[$daemon_name_v6];
          }
        } # config_file_v6
      } # config_tmpl_v6
    } # manage_conf
  } # enable_v6

} # Class:: bird
