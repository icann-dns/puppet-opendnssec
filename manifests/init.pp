# @summary class to manage opendnssec
# @param enabled enable this module
# @param user user to run opendnssec
# @param group group to run opendnssec
# @param manage_packages manage packages
# @param manage_datastore manage datastore
# @param manage_service manage service
# @param manage_ods_ksmutil manage ods-ksmutil
# @param manage_conf manage conf
# @param opendnssec_version opendnssec version
# @param logging_level logging level
# @param logging_facility logging facility
# @param packages packages to install
# @param service_enforcer service enforcer
# @param service_signer service signer
# @param sqlite_packages sqlite packages
# @param mysql_packages mysql packages
# @param repository_name repository name
# @param repository_module repository module
# @param repository_pin repository pin
# @param repository_capacity repository capacity
# @param repository_token_label repository token label
# @param skip_publickey skip publickey
# @param datastore_engine datastore engine
# @param datastore_host datastore host
# @param datastore_port datastore port
# @param datastore_name datastore name
# @param datastore_user datastore user
# @param datastore_password datastore password
# @param mysql_sql_file mysql sql file
# @param base_dir base dir
# @param policy_file policy file
# @param zone_file zone file
# @param tsigs_dir tsigs dir
# @param remotes_dir remotes dir
# @param xsl_file xsl file
# @param sqlite_file sqlite file
# @param working_dir working dir
# @param signconf_dir signconf dir
# @param signed_dir signed dir
# @param unsigned_dir unsigned dir
# @param ksmutil_path ksmutil path
# @param enforcer_path enforcer path
# @param listener_address listener address
# @param listener_port listener port
# @param xferout_enabled xferout enabled
# @param zones zones
# @param policies policies
# @param remotes remotes
# @param tsigs tsigs
# @param default_tsig_name default tsig name
# @param default_policy_name default policy name
# @param default_masters default masters
# @param default_provide_xfrs default provide xfrs
# @param notify_boolean notify boolean
# @param notify_command notify command
# @param require_backup require backup
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
  String[1,10]                  $opendnssec_version,
  Integer[1,7]                  $logging_level,
  Tea::Syslogfacility           $logging_facility,
  Array[String]                 $packages,
  String[1,100]                 $service_enforcer,
  String[1,100]                 $service_signer,
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
  Stdlib::Absolutepath          $enforcer_path,
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
  Boolean                       $require_backup,
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
  file { $xsl_file:
    ensure => file,
    source => 'puppet:///modules/opendnssec/usr/share/opendnssec/addns.xsl',
  }
  file {[$tsigs_dir, $remotes_dir, $signconf_dir, $working_dir]:
    ensure => 'directory',
    owner  => $user,
    group  => $group,
  }
  if $enabled and $manage_datastore {
    if $manage_conf {
      if $manage_ods_ksmutil and ( versioncmp($opendnssec_version, '1') >= 0 ) {
        $datastore_setup_before = Exec['ods-ksmutil updated conf.xml']
      } elsif ( versioncmp($opendnssec_version, '2') >= 0 ) {
        $datastore_setup_before = Exec['ods-enforcer updated conf.xml']
      }
      else {
        $datastore_setup_before = undef
      }
    }
    else {
      $datastore_setup_before = undef
    }
    if $datastore_engine == 'mysql' {
      require  mysql::server
      mysql::db { $datastore_name:
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
      if ( $manage_ods_ksmutil and ( versioncmp($opendnssec_version, '1') >= 0 ) ) {
        exec { 'ods-ksmutil setup':
          path     => ['/bin', '/usr/bin', '/sbin', '/usr/sbin', '/usr/local/bin'],
          provider => 'shell',
          command  => "/usr/bin/yes | ${ksmutil_path} setup",
          unless   => "test -s ${sqlite_file}",
          before   => $datastore_setup_before,
        }
      } elsif ( versioncmp($opendnssec_version, '2') >= 0) {
        exec { 'ods-enforcer-db-setup':
          path     => ['/sbin', '/usr/sbin', '/usr/local/sbin'],
          provider => 'shell',
          command  => "/usr/bin/yes | ${enforcer_path} setup",
          unless   => "test -s ${sqlite_file}",
          before   => $datastore_setup_before,
        }
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
    opendnssec::addns { 'default':
      masters      => $default_masters,
      provide_xfrs => $default_provide_xfrs,
    }
    if $enabled {
      if $manage_conf {
        $exec_subscribe = File['/etc/opendnssec/conf.xml']
      } else {
        $exec_subscribe = undef
      }
      if $manage_ods_ksmutil and ( versioncmp($opendnssec_version, '1') >= 0 ) {
        exec { 'ods-ksmutil updated conf.xml':
          command     => "/usr/bin/yes | ${ksmutil_path} update conf",
          user        => $user,
          refreshonly => true,
          subscribe   => $exec_subscribe,
        }
      } elsif ( versioncmp($opendnssec_version, '2') >= 0) {
        exec { 'ods-enforcer updated conf.xml':
          command     => "/usr/bin/yes | ${enforcer_path} update conf",
          user        => $user,
          refreshonly => true,
          subscribe   => $exec_subscribe,
        }
      }
      file { '/etc/opendnssec/MASTER':
        ensure => 'file',
        mode   => '0644',
        owner  => $user,
        group  => $group;
      }
    } else {
      file { '/etc/opendnssec/MASTER':
        ensure => 'absent',
      }
    }
  }
  if ! defined(Class['opendnssec::policies']) {
    class { 'opendnssec::policies': policies => $policies }
  }
  if ! defined(Opendnssec::Policy[$default_policy_name]) {
    opendnssec::policy { $default_policy_name: }
  }
  if ! defined(Class['opendnssec::zones']) {
    class { 'opendnssec::zones': zones => $zones }
  }
  file { '/var/lib/opendnssec/enforcer/zones.xml':
    ensure  => 'link',
    target  => '/etc/opendnssec/zonelist.xml',
    replace => true,
    links   => manage,
  }

  if $enabled and $manage_service {
    service { $service_enforcer:
      ensure => running,
      enable => true,
    } ~> service { $service_signer:
      ensure => running,
      enable => true,
    }
    Opendnssec::Tsig   <| |> ~> Service[$service_enforcer, $service_signer]
    Opendnssec::Zone   <| |> -> Service[$service_enforcer, $service_signer]
    Opendnssec::Addns  <| |> ~> Service[$service_enforcer, $service_signer]
    Opendnssec::Policy <| |> -> Service[$service_enforcer, $service_signer]
    Opendnssec::Remote <| |> ~> Service[$service_enforcer, $service_signer]
  }
}
