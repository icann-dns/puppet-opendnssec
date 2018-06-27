# == Class: opendnssec
#
class opendnssec (
  Boolean               $enabled                = true,
  String[1,32]          $user                   = 'root',
  String[1,32]          $group                  = 'root',

  Boolean               $manage_packages        = true,
  Boolean               $manage_datastore       = true,
  Boolean               $manage_service         = true,
  Boolean               $manage_ods_ksmutil     = true,
  Boolean               $manage_conf            = true,

  Integer[1,7]          $logging_level          = 3,
  Tea::Syslogfacility   $logging_facility       = 'local0',

  String[1,100]         $repository_name        = 'SoftHSM',
  Stdlib::Absolutepath  $repository_module      = $::opendnssec::params::repository_module,
  String[1,100]         $repository_pin         = '1234',
  Optional[Integer]     $repository_capacity    = undef,
  String[1,32]          $repository_token_label = 'OpenDNSSEC',
  Boolean               $skip_publickey         = true,
  Boolean               $require_backup         = false,

  Opendnssec::Datastore $datastore_engine       = 'mysql',
  Tea::Host             $datastore_host         = 'localhost',
  Tea::Port             $datastore_port         = 3306,
  String[1,100]         $datastore_name         = 'kasp',
  String[1,100]         $datastore_user         = 'opendnssec',
  String[1,100]         $datastore_password     = 'change_me',
  Stdlib::Absolutepath  $mysql_sql_file         = '/usr/share/opendnssec/database_create.mysql',

  Stdlib::Absolutepath  $policy_file            = '/etc/opendnssec/kasp.xml',
  Stdlib::Absolutepath  $zone_file              = '/etc/opendnssec/zonelist.xml',
  Stdlib::Absolutepath  $tsigs_dir              = '/etc/opendnssec/tsigs',
  Stdlib::Absolutepath  $remotes_dir            = '/etc/opendnssec/remotes',
  Stdlib::Absolutepath  $xsl_file               = '/usr/share/opendnssec/addns.xsl',

  Boolean               $xferout_enabled        = true,

  Hash                  $zones                  = {},
  Hash                  $policies               = {},
  Hash                  $remotes                = {},
  Hash                  $tsigs                  = {},
  String                $default_tsig_name      = 'NOKEY',
  String                $default_policy_name    = 'default',
  Array[String]         $default_masters        = [],
  Array[String]         $default_provide_xfrs   = [],

) inherits opendnssec::params {

  if $manage_packages {
    ensure_packages(['opendnssec', 'xsltproc'])
    file {'/var/lib/opendnssec':
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
  file {[$tsigs_dir, $remotes_dir]:
    ensure => 'directory',
    owner  => $user,
    group  => $group,
  }
  if $enabled and $manage_datastore {
    if $datastore_engine == 'mysql' {
      if $manage_ods_ksmutil and $manage_conf {
        $mysql_db_before = Exec['ods-ksmutil updated conf.xml']
      } else {
        $mysql_db_before = undef
      }
      require  ::mysql::server
      mysql::db {$datastore_name:
        user     => $datastore_user,
        password => $datastore_password,
        sql      => $mysql_sql_file,
        before   => $mysql_db_before,
      }

      if $manage_packages {
        ensure_packages(['opendnssec-enforcer-mysql'])
      }
    } elsif $datastore_engine == 'sqlite' {
      ensure_packages(['opendnssec-enforcer-sqlite'])
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
          command     => '/usr/bin/yes | /usr/bin/ods-ksmutil update conf',
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
    service {'opendnssec-enforcer':
      ensure => running,
      enable => true,
    } ~> service { 'opendnssec-signer':
      ensure => running,
      enable => true,
    }
    Opendnssec::Tsig<| |> ~> Service['opendnssec-enforcer', 'opendnssec-signer']
    Opendnssec::Zone<| |> -> Service['opendnssec-enforcer', 'opendnssec-signer']
    Opendnssec::Addns<| |> ~> Service['opendnssec-enforcer', 'opendnssec-signer']
    Opendnssec::Policy<| |> -> Service['opendnssec-enforcer', 'opendnssec-signer']
    Opendnssec::Remote<| |> ~> Service['opendnssec-enforcer', 'opendnssec-signer']
  }
}
