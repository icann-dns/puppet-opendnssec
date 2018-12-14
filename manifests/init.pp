# == Class: opendnssec
#
class opendnssec (
  Boolean                       $enabled,
  String[1,32]                  $user,
  String[1,32]                  $group,

  Boolean                       $manage_packages,
  Boolean                       $manage_datastore,
  Boolean                       $manage_service,
  Boolean                       $manage_ods_ksmutil,
  Boolean                       $manage_conf,

  Integer[1,7]                  $logging_level,
  Tea::Syslogfacility           $logging_facility,

  Array[String]                 $packages,
  Array[String]                 $services,
  Array[String]                 $sqlite_packages,
  Array[String]                 $mysql_packages,

  String[1,100]                 $repository_name,
  Stdlib::Absolutepath          $repository_module,
  String[1,100]                 $repository_pin,
  Optional[Integer]             $repository_capacity,
  String[1,32]                  $repository_token_label,
  Boolean                       $skip_publickey,

  Opendnssec::Datastore         $datastore_engine,
  Stdlib::Host                  $datastore_host,
  Stdlib::Port                  $datastore_port,
  String[1,100]                 $datastore_name,
  String[1,100]                 $datastore_user,
  String[1,100]                 $datastore_password,
  Stdlib::Absolutepath          $mysql_sql_file,

  Stdlib::Absolutepath          $base_dir,
  Stdlib::Absolutepath          $policy_file,
  Stdlib::Absolutepath          $zone_file,
  Stdlib::Absolutepath          $tsigs_dir,
  Stdlib::Absolutepath          $remotes_dir,
  Stdlib::Absolutepath          $xsl_file,
  Stdlib::Absolutepath          $sqlite_file,
  Stdlib::Absolutepath          $working_dir,
  Stdlib::Absolutepath          $signconf_dir,
  Stdlib::Absolutepath          $signed_dir,
  Stdlib::Absolutepath          $unsigned_dir,
  Stdlib::Absolutepath          $ksmutil_path,

  Optional[Stdlib::Ip::Address] $listener_address,
  Stdlib::Port                  $listener_port,

  Boolean                       $xferout_enabled,

  Hash                          $zones,
  Hash                          $policies,
  Hash                          $remotes,
  Hash                          $tsigs,
  String                        $default_tsig_name,
  String                        $default_policy_name,
  Array[String]                 $default_masters,
  Array[String]                 $default_provide_xfrs,
  Boolean                       $notify_boolean,
  String                        $notify_command,
  Boolean                       $require_backup       = true,
) {

  if $facts['os']['family'] == 'RedHat' and $datastore_engine == 'mysql' {
    fail('RedHat does not support mysql')
  }

  if $manage_packages {
    ensure_packages($packages)
    file {[$base_dir, $signed_dir, $unsigned_dir]:
      ensure => 'directory',
      mode   => '0640',
      owner  => $user,
      group  => $group;
    }
  }
  file {$xsl_file:
    ensure => file,
    source => 'puppet:///modules/opendnssec/usr/share/opendnssec/addns.xsl',
  }
  file {[$tsigs_dir, $remotes_dir, $signconf_dir, $working_dir]:
    ensure => 'directory',
    owner  => $user,
    group  => $group,
  }
  if $enabled and $manage_datastore {
    if $manage_ods_ksmutil and $manage_conf {
      $datastore_setup_before = Exec['ods-ksmutil updated conf.xml']
    } else {
      $datastore_setup_before = undef
    }
    if $datastore_engine == 'mysql' {
      require  ::mysql::server
      mysql::db {$datastore_name:
        user     => $datastore_user,
        password => $datastore_password,
        sql      => $mysql_sql_file,
        before   => $datastore_setup_before,
      }

      if $manage_packages {
        ensure_packages($mysql_packages)
      }
    } elsif $datastore_engine == 'sqlite' {
      if $manage_packages {
        ensure_packages($sqlite_packages)
      }

      exec {'ods-ksmutil setup':
        path     => ['/bin', '/usr/bin', '/sbin', '/usr/sbin', '/usr/local/bin'],
        provider => 'shell',
        command  => "/usr/bin/yes | ${ksmutil_path} setup",
        unless   => "test -s ${sqlite_file}",
        before   => $datastore_setup_before,
      }
    }
  }
  if $manage_conf {

    create_resources(opendnssec::tsig, $tsigs)
    if $default_tsig_name != 'NOKEY' and ! defined(Opendnssec::Tsig[$default_tsig_name]) {
      fail("Opendnssec::Tsig['${default_tsig_name}'] defined by default_tsig_name does not exist")
    }

    create_resources(opendnssec::remote, $remotes)
    $default_masters.each |String $master| {
      if ! defined(Opendnssec::Remote[$master]) {
        fail("Opendnssec::Remote['${master}'] defined by default_master does not exist")
      }
    }
    $default_provide_xfrs.each |String $provide_xfr| {
      if ! defined(Opendnssec::Remote[$provide_xfr]) {
        fail("Opendnssec::Remote['${provide_xfr}'] defined by default_provide_xfr does not exist")
      }
    }
    file { '/etc/opendnssec/conf.xml':
      ensure  => 'file',
      mode    => '0644',
      owner   => $user,
      group   => $group,
      content => template('opendnssec/etc/opendnssec/conf.xml.erb');
    }
    opendnssec::addns {'default':
      masters      => $default_masters,
      provide_xfrs => $default_provide_xfrs,
    }
    if $enabled {
      if $manage_conf {
        $exec_subscribe = File['/etc/opendnssec/conf.xml']
      } else {
        $exec_subscribe = undef
      }
      if $manage_ods_ksmutil {
        exec {'ods-ksmutil updated conf.xml':
          command     => "/usr/bin/yes | ${ksmutil_path} update all",
          user        => $user,
          refreshonly => true,
          subscribe   => $exec_subscribe,
        }
      }
      file {'/etc/opendnssec/MASTER':
        ensure => 'file',
        mode   => '0644',
        owner  => $user,
        group  => $group;
      }
    } else {
      file {'/etc/opendnssec/MASTER':
        ensure => 'absent',
      }
    }
  }
  if ! defined(Class['opendnssec::policies']) {
    class { '::opendnssec::policies': policies => $policies }
  }
  if ! defined(Opendnssec::Policy[$default_policy_name]) {
    opendnssec::policy { $default_policy_name: }
  }
  if ! defined(Class['opendnssec::zones']) {
    class { '::opendnssec::zones': zones => $zones }
  }
  if $enabled and $manage_service {
    service {
      $services:
        ensure => running,
        enable => true,
    }
  }
}
